import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';

/// Reads a provider; both `WidgetRef.read` and `ProviderContainer.read`
/// tear off to this type.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Makes [document] the open document in the drawing providers.
///
/// The undo history is global, so it is emptied here: undo must never apply
/// the previous notebook's commands to [document] (#149). The canvas
/// transform is global too: [document] opens at the default view (zoom 1.0,
/// baseline 1.0, default origin), and a limited-canvas document is fitted to
/// its page by the caller afterwards (#474).
void startEditorSession(ProviderReader read, DrawingDocument document) {
  read(canvasTransformProvider.notifier).resetForNewDocument();
  read(documentProvider.notifier).updateDocument(document);
  read(currentDocumentProvider.notifier).state = document;
  final pageManager = read(pageManagerProvider.notifier);
  pageManager.initializeFromDocument(
    document.pages,
    currentIndex: document.currentPageIndex,
  );
  read(historyManagerProvider.notifier).clearHistory();
}

/// Whether [next] differs from [previous] only in view state (current page,
/// active layer) of the same document. Such a change is not an edit: it must
/// not rewrite the notebook or bump its modified date (#467).
bool isViewOnlyChange(DrawingDocument previous, DrawingDocument next) {
  if (previous.id != next.id || !previous.isMultiPage || !next.isMultiPage) {
    return false;
  }
  final asNext = previous.copyWith(
    currentPageIndex: next.currentPageIndex,
    activeLayerIndex: next.activeLayerIndex,
  );
  return asNext == next;
}

/// The editor's reaction to a change of the open document: an edit is
/// scheduled for autosave and marks the session unsaved; a view-only change
/// (see [isViewOnlyChange]) is not saved on its own.
void onEditorDocumentChanged(
  ProviderReader read,
  DrawingDocument previous,
  DrawingDocument next,
) {
  if (previous == next || previous.id != next.id) return;
  read(currentDocumentProvider.notifier).state = next;
  if (isViewOnlyChange(previous, next)) {
    read(autoSaveProvider.notifier).viewChanged(next);
    return;
  }
  read(autoSaveProvider.notifier).documentChanged(next);
  read(hasUnsavedChangesProvider.notifier).state = true;
}

/// Commits the text box being typed in, if any, so it is part of the next
/// save (#489). Typed text lives only in the text tool until it is committed;
/// an empty text box creates nothing. The commit is reported to autosave
/// here as well, so it does not depend on the editor's document listener.
void commitTextBeingEdited(ProviderReader read) {
  final before = read(documentProvider);
  read(textToolActionsProvider).commit();
  final after = read(documentProvider);
  if (!identical(before, after)) onEditorDocumentChanged(read, before, after);
}

/// Writes what is left to save before the editor closes: the text being
/// typed (see [commitTextBeingEdited]), a pending or failed save, after
/// waiting for one that is running. Nothing is written when the notebook was
/// only read. Returns false when the save failed; the editor then stays open
/// and its banner offers Retry.
Future<bool> saveBeforeLeavingEditor(ProviderReader read) async {
  commitTextBeingEdited(read);
  await read(autoSaveProvider.notifier).flush();
  return read(saveFailureProvider) == null;
}

/// Moves the open notebook [documentId] to the trash from the editor (#480).
/// Its edits are saved first, so a restored notebook keeps them and no
/// autosave can fire (and resurrect it) after the trash. Returns false
/// without trashing when that save failed (the editor stays open and its
/// banner offers Retry), and false when the trash itself failed.
Future<bool> moveOpenDocumentToTrash(
  ProviderReader read,
  String documentId,
) async {
  if (!await saveBeforeLeavingEditor(read)) return false;
  return read(documentsControllerProvider.notifier).moveToTrash(documentId);
}

/// Drops the undo history of the document that is being closed and the
/// session's "Locate PDF…" handler (it holds the editor's context).
void endEditorSession(ProviderReader read) {
  read(historyManagerProvider.notifier).clearHistory();
  read(pdfSourceRelinkProvider.notifier).state = null;
}

/// Resets every provider that holds state of the open document.
///
/// Shared by all ways of leaving the editor (back, move to trash) so a later
/// reopen of the same notebook starts a fresh session. [invalidate] is
/// `ref.invalidate` or `ProviderContainer.invalidate`. Invalidating
/// [autoSaveProvider] drops any pending autosave timer.
///
/// The library lists are non-autoDispose and only refresh on invalidation,
/// so they are reloaded here to show the saved title, cover, page count and
/// modified date (and the Recent order) when the library comes back (#464).
///
/// Reader mode, dual-page mode and the rendered PDF page cache are global
/// too: the next notebook must open editable in single-page view, and the
/// closed notebook's page renders (up to 50 MB) are freed. The thumbnail
/// cache is kept: library previews use it (#481).
void closeEditorSession(
  ProviderReader read,
  void Function(ProviderOrFamily provider) invalidate,
) {
  invalidate(documentsProvider);
  invalidate(favoriteDocumentsProvider);
  invalidate(recentDocumentsProvider);
  invalidate(documentProvider);
  invalidate(pageManagerProvider);
  invalidate(autoSaveProvider);
  invalidate(saveDocumentUseCaseProvider);
  invalidate(hasUnsavedChangesProvider);
  invalidate(saveFailureProvider);
  invalidate(pageTrashCallbackProvider);
  invalidate(pageTrashDiscardCallbackProvider);
  invalidate(readerModeProvider);
  invalidate(dualPageModeProvider);
  read(pdfPageCacheProvider.notifier).state = {};
  endEditorSession(read);
  // Reset, not invalidate: a pinch still in flight holds the notifier.
  read(canvasTransformProvider.notifier).resetForNewDocument();
  read(visiblePdfPageProvider.notifier).state = null;
  read(currentPdfFilePathProvider.notifier).state = null;
  read(totalPdfPagesProvider.notifier).state = 0;
}

/// Drops the trash entry of a page whose delete was undone (#460).
///
/// The page is back in the document, so this must never be "delete
/// forever": that would remove the page's image and PDF files once the
/// stored content no longer references them.
PageTrashDiscardCallback pageTrashDiscardCallbackFor(ProviderReader read) {
  return (trashId) =>
      read(documentsControllerProvider.notifier).discardTrashedPage(trashId);
}

/// Soft-deletes pages of [documentId] into the page trash.
///
/// The notebook title is read when a page is trashed, not captured at load,
/// so a rename made in the editor is reflected in later trash entries.
PageTrashCallback pageTrashCallbackFor(ProviderReader read, String documentId) {
  return (pageIndex, page) =>
      read(documentsControllerProvider.notifier).movePageToTrash(
        documentId: documentId,
        documentTitle: read(documentProvider).title,
        pageIndex: pageIndex,
        pageData: page.toJson(),
      );
}
