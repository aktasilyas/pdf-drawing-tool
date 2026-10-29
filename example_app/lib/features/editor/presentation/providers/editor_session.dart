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
/// the previous notebook's commands to [document] (#149).
void startEditorSession(ProviderReader read, DrawingDocument document) {
  read(documentProvider.notifier).updateDocument(document);
  read(currentDocumentProvider.notifier).state = document;
  final pageManager = read(pageManagerProvider.notifier);
  pageManager.initializeFromDocument(
    document.pages,
    currentIndex: document.currentPageIndex,
  );
  read(historyManagerProvider.notifier).clearHistory();
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
  endEditorSession(read);
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
