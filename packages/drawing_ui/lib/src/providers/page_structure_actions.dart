import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_provider.dart';
import 'page_provider.dart';
import 'page_trash_callback_provider.dart';

/// A page removed by [PageStructureActions.deletePage], with everything
/// needed to put it back.
class DeletedPage {
  const DeletedPage({
    required this.page,
    required this.index,
    required this.wasCurrent,
    this.trashId,
  });

  /// The removed page (same id and layers).
  final Page page;

  /// Position the page had before removal.
  final int index;

  /// Whether the page was the current one.
  final bool wasCurrent;

  /// Id of the trash entry written on delete, if the host app has a trash.
  final String? trashId;
}

/// Page structure changes (move, delete, restore).
///
/// `documentProvider` is the single source of truth; `pageManagerProvider` is
/// synced afterwards so the sidebar and canvas follow.
class PageStructureActions {
  PageStructureActions(this._ref);

  final Ref _ref;

  /// Moves the page at [from] to position [to].
  void movePage(int from, int to) {
    final doc = _ref.read(documentProvider);
    final moved = doc.movePage(from, to);
    if (identical(moved, doc)) return;
    _apply(moved);
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
    if (freshIndex < 0) return null;
    _apply(fresh.removePage(freshIndex));
    return DeletedPage(
      page: page,
      index: index,
      wasCurrent: wasCurrent,
      trashId: trashId,
    );
  }

  /// Puts a deleted page back at its old index and drops its trash entry.
  Future<void> restorePage(DeletedPage deleted) async {
    final doc = _ref.read(documentProvider);
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
