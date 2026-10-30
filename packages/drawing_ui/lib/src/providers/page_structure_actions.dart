import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_provider.dart';
import 'history_provider.dart';
import 'page_provider.dart';
import 'page_trash_callback_provider.dart';

/// A page removed by [PageStructureActions.deletePage], with everything
/// needed to put it back.
class DeletedPage {
  const DeletedPage({
    required this.documentId,
    required this.page,
    required this.index,
    required this.wasCurrent,
    this.trashId,
  });

  /// Id of the document the page was removed from.
  final String documentId;

  /// The removed page (same id and layers).
  final Page page;

  /// Position the page had before removal.
  final int index;

  /// Whether the page was the current one.
  final bool wasCurrent;

  /// Id of the trash entry written on delete, if the host app has a trash.
  final String? trashId;
}

/// Undo token for an insert or a move made by [PageStructureActions].
class PageStructureChange {
  const PageStructureChange({
    required this.documentId,
    required this.previousOrder,
    required this.previousCurrentId,
    this.insertedPageIds = const [],
    this.insertedPageLayers = const {},
  });

  /// Id of the document the change was made in.
  final String documentId;

  /// Page ids in their order before the change.
  final List<String> previousOrder;

  /// Id of the current page before the change.
  final String previousCurrentId;

  /// Ids of the pages the change inserted (empty for a move).
  final List<String> insertedPageIds;

  /// The layers each inserted page held when it was inserted, by page id
  /// (a duplicate or pasted page starts with content).
  final Map<String, List<Layer>> insertedPageLayers;
}

/// Whether [page] was edited since [snapshot] was taken.
///
/// Layers are immutable, so any edit (stroke, erase, shape, text, image,
/// sticky note, move) replaces at least one [Layer] instance. A page with no
/// snapshot counts as changed, so its content is never dropped.
bool _changedSince(Page page, List<Layer>? snapshot) {
  if (snapshot == null || snapshot.length != page.layers.length) return true;
  for (var i = 0; i < snapshot.length; i++) {
    if (!identical(snapshot[i], page.layers[i])) return true;
  }
  return false;
}

/// Page structure changes (insert, move, delete, restore).
///
/// `documentProvider` is the single source of truth; `pageManagerProvider` is
/// synced afterwards so the sidebar and canvas follow.
class PageStructureActions {
  PageStructureActions(this._ref);

  final Ref _ref;

  /// Moves the page at [from] to position [to]. Returns null when nothing
  /// moved.
  PageStructureChange? movePage(int from, int to) {
    final doc = _ref.read(documentProvider);
    final moved = doc.movePage(from, to);
    if (identical(moved, doc)) return null;
    final change = _changeFrom(doc);
    _apply(moved);
    return change;
  }

  /// Inserts [page] at [index] (clamped) and makes it the current page.
  PageStructureChange insertPage(int index, Page page) =>
      insertPages(index, [page])!;

  /// Inserts [pages] in order at [index] (clamped) into the latest document
  /// and makes the first one current. One [undo] removes all of them.
  /// Returns null when [pages] is empty.
  PageStructureChange? insertPages(int index, List<Page> pages) {
    if (pages.isEmpty) return null;
    final doc = _ref.read(documentProvider);
    final change = _changeFrom(
      doc,
      insertedPageIds: [for (final p in pages) p.id],
      insertedPageLayers: {for (final p in pages) p.id: p.layers},
    );
    // A cover stays page 1, so nothing is inserted before it.
    final floor = doc.pages.isNotEmpty && doc.pages.first.isCover ? 1 : 0;
    final at = index.clamp(floor, doc.pages.length);
    final list = List<Page>.from(doc.pages)..insertAll(at, pages);
    _apply(doc.replacePages(list, currentPageId: pages.first.id));
    return change;
  }

  /// Inserts a copy of [source] with fresh page, layer and element ids right
  /// after [afterIndex] and makes it the current page.
  PageStructureChange insertCopy(int afterIndex, Page source) =>
      insertPage(afterIndex + 1, source.copyWithFreshIds());

  /// Reverts an insert or a move: restores the previous page order and
  /// current page, keeping the pages' current content.
  ///
  /// An inserted page that was edited in any way since the insert is moved
  /// to the page trash first; content is never dropped.
  ///
  /// Returns false (and changes nothing) when another document is loaded, the
  /// set of pages changed in some other way since, or a page with new content
  /// could not be stored in the trash (no trash, it returned null or threw).
  Future<bool> undo(PageStructureChange change) async {
    final pages = _revertablePages(change);
    if (pages == null) return false;
    final doc = _ref.read(documentProvider);
    // Inserted pages edited since the insert, with their index.
    final gained = [
      for (final id in change.insertedPageIds)
        if (_changedSince(pages[id]!, change.insertedPageLayers[id]))
          (index: doc.pages.indexOf(pages[id]!), page: pages[id]!),
    ];

    final trashIds = <String>[];
    if (gained.isNotEmpty) {
      final trash = _ref.read(pageTrashCallbackProvider);
      if (trash == null) return false;
      try {
        for (final g in gained) {
          final id = await trash(g.index, g.page);
          if (id == null) {
            await _discardTrash(trashIds);
            return false;
          }
          trashIds.add(id);
        }
      } catch (_) {
        await _discardTrash(trashIds);
        return false;
      }
    }

    // The document may have changed while the trash calls ran.
    final fresh = _revertablePages(change);
    if (fresh == null) {
      await _discardTrash(trashIds);
      return false;
    }
    _apply(_ref.read(documentProvider).replacePages(
      [for (final id in change.previousOrder) fresh[id]!],
      currentPageId: change.previousCurrentId,
    ));
    return true;
  }

  Future<void> _discardTrash(List<String> trashIds) async {
    final discard = _ref.read(pageTrashDiscardCallbackProvider);
    if (discard == null) return;
    for (final id in trashIds) {
      await discard(id);
    }
  }

  /// Pages by id when [change] can still be reverted, else null.
  Map<String, Page>? _revertablePages(PageStructureChange change) {
    final doc = _ref.read(documentProvider);
    if (doc.id != change.documentId) return null;
    final byId = {for (final p in doc.pages) p.id: p};
    final expected = {
      ...change.previousOrder,
      ...change.insertedPageIds,
    };
    if (byId.length != expected.length || !expected.every(byId.containsKey)) {
      return null;
    }
    return byId;
  }

  /// Deletes the page at [index]. Returns null when it is the last page.
  ///
  /// The page is soft-deleted through [pageTrashCallbackProvider] when the
  /// host app provides one.
  Future<DeletedPage?> deletePage(int index) async {
    final doc = _ref.read(documentProvider);
    if (doc.pages.length <= 1 || index < 0 || index >= doc.pages.length) {
      return null;
    }
    final page = doc.pages[index];
    final wasCurrent = doc.currentPageIndex == index;

    final trashCallback = _ref.read(pageTrashCallbackProvider);
    final trashId =
        trashCallback == null ? null : await trashCallback(index, page);

    // Re-read: the document may have changed while the trash call was running.
    final fresh = _ref.read(documentProvider);
    final freshIndex = fresh.pages.indexWhere((p) => p.id == page.id);
    if (freshIndex < 0) {
      // Page is already gone: drop the trash entry we just wrote.
      final discard = _ref.read(pageTrashDiscardCallbackProvider);
      if (trashId != null && discard != null) await discard(trashId);
      return null;
    }
    _apply(fresh.removePage(freshIndex));
    _ref.read(historyManagerProvider.notifier).discardDeletedPages();
    return DeletedPage(
      documentId: fresh.id,
      page: page,
      index: index,
      wasCurrent: wasCurrent,
      trashId: trashId,
    );
  }

  /// Puts a deleted page back at its old index and drops its trash entry.
  Future<void> restorePage(DeletedPage deleted) async {
    final doc = _ref.read(documentProvider);
    if (doc.id != deleted.documentId) return;
    if (doc.pages.any((p) => p.id == deleted.page.id)) return;
    var restored = doc.insertPageAt(deleted.index, deleted.page);
    if (deleted.wasCurrent) {
      final at = restored.pages.indexWhere((p) => p.id == deleted.page.id);
      restored = restored.setCurrentPage(at);
    }
    _apply(restored);

    final trashId = deleted.trashId;
    final discard = _ref.read(pageTrashDiscardCallbackProvider);
    if (trashId != null && discard != null) await discard(trashId);
  }

  PageStructureChange _changeFrom(
    DrawingDocument doc, {
    List<String> insertedPageIds = const [],
    Map<String, List<Layer>> insertedPageLayers = const {},
  }) =>
      PageStructureChange(
        documentId: doc.id,
        previousOrder: [for (final p in doc.pages) p.id],
        previousCurrentId: doc.pages[doc.currentPageIndex].id,
        insertedPageIds: insertedPageIds,
        insertedPageLayers: insertedPageLayers,
      );

  void _apply(DrawingDocument doc) {
    _ref.read(documentProvider.notifier).updateDocument(doc);
    _ref.read(pageManagerProvider.notifier).initializeFromDocument(
          doc.pages,
          currentIndex: doc.currentPageIndex,
        );
  }
}

/// Provides [PageStructureActions].
final pageStructureActionsProvider = Provider<PageStructureActions>(
  PageStructureActions.new,
);
