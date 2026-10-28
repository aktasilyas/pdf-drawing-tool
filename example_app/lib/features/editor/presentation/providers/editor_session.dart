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

/// Drops the undo history of the document that is being closed.
void endEditorSession(ProviderReader read) {
  read(historyManagerProvider.notifier).clearHistory();
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
