import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_provider.dart';
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
    this.insertedPageId,
    this.insertedPageInk = 0,
  });

  /// Id of the document the change was made in.
  final String documentId;

  /// Page ids in their order before the change.
  final List<String> previousOrder;

  /// Id of the current page before the change.
  final String previousCurrentId;

  /// Id of the page the change inserted, if any.
  final String? insertedPageId;

  /// Strokes, shapes and texts the inserted page held when it was inserted
  /// (a duplicate or pasted page starts with some).
  final int insertedPageInk;
}

int _inkCount(Page p) => p.strokeCount + p.shapeCount + p.textCount;

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
  PageStructureChange insertPage(int index, Page page) {
    final doc = _ref.read(documentProvider);
    final change = _changeFrom(
      doc,
      insertedPageId: page.id,
      insertedPageInk: _inkCount(page),
    );
    final inserted = doc.insertPageAt(index, page);
    _apply(inserted.replacePages(inserted.pages, currentPageId: page.id));
    return change;
  }

  /// Inserts a copy of [source] with fresh page, layer and element ids right
  /// after [afterIndex] and makes it the current page.
  PageStructureChange insertCopy(int afterIndex, Page source) =>
      insertPage(afterIndex + 1, source.copyWithFreshIds());

  /// Reverts an insert or a move: restores the previous page order and
  /// current page, keeping the pages' current content.
  ///
  /// An inserted page that gained content since the insert is moved to the
  /// page trash (when the host app has one) instead of being dropped.
  ///
  /// Returns false (and changes nothing) when another document is loaded or
  /// the set of pages changed in some other way since.
  Future<bool> undo(PageStructureChange change) async {
    final pages = _revertablePages(change);
    if (pages == null) return false;
    final insertedId = change.insertedPageId;
    final inserted = insertedId == null ? null : pages[insertedId];
    final trash = _ref.read(pageTrashCallbackProvider);
    if (inserted != null &&
        trash != null &&
        _inkCount(inserted) > change.insertedPageInk) {
      final index = _ref.read(documentProvider).pages.indexOf(inserted);
      await trash(index, inserted);
    }
    // Re-validate: the document may have changed while the trash call ran.
    final fresh = _revertablePages(change);
    if (fresh == null) return false;
    _apply(_ref.read(documentProvider).replacePages(
      [for (final id in change.previousOrder) fresh[id]!],
      currentPageId: change.previousCurrentId,
    ));
    return true;
  }

  /// Pages by id when [change] can still be reverted, else null.
  Map<String, Page>? _revertablePages(PageStructureChange change) {
    final doc = _ref.read(documentProvider);
    if (doc.id != change.documentId) return null;
    final byId = {for (final p in doc.pages) p.id: p};
    final expected = {
      ...change.previousOrder,
      if (change.insertedPageId != null) change.insertedPageId!,
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
    String? insertedPageId,
    int insertedPageInk = 0,
  }) =>
      PageStructureChange(
        documentId: doc.id,
        previousOrder: [for (final p in doc.pages) p.id],
        previousCurrentId: doc.pages[doc.currentPageIndex].id,
        insertedPageId: insertedPageId,
        insertedPageInk: insertedPageInk,
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
