import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/providers/trash_providers.dart';
import 'package:example_app/features/premium/premium.dart';

/// Refreshes every document list, folder counts and document counts.
void invalidateAllDocumentLists(Ref ref) {
  ref.invalidate(documentsProvider);
  ref.invalidate(favoriteDocumentsProvider);
  ref.invalidate(recentDocumentsProvider);
  ref.invalidate(trashDocumentsProvider);
  ref.invalidate(foldersProvider); // Folder counts need refresh too!
  ref.invalidate(totalDocumentCountProvider);
  ref.invalidate(notebookCountProvider);
}

/// Refreshes only the providers an operation affects.
/// Set [documentCount] to true when the total document count changes
/// (create, duplicate, permanent delete — NOT move to trash).
void invalidateDocumentLists(
  Ref ref, {
  bool documents = false,
  bool favorites = false,
  bool recent = false,
  bool trash = false,
  bool folders = false,
  bool documentCount = false,
}) {
  if (documents) ref.invalidate(documentsProvider);
  if (favorites) ref.invalidate(favoriteDocumentsProvider);
  if (recent) ref.invalidate(recentDocumentsProvider);
  if (trash) ref.invalidate(trashDocumentsProvider);
  if (folders) ref.invalidate(foldersProvider);
  if (documentCount) {
    ref.invalidate(totalDocumentCountProvider);
    ref.invalidate(notebookCountProvider);
  }
}

/// Refreshes the lists a move to or from the trash changes: documents,
/// favorites, recent, trash and folders (for counts).
void invalidateTrashMove(Ref ref) {
  invalidateDocumentLists(
    ref,
    documents: true,
    favorites: true,
    recent: true,
    trash: true,
    folders: true,
  );
}

/// Refreshes the page-trash lists.
void invalidatePageTrash(Ref ref) {
  ref.invalidate(trashedPagesProvider);
  ref.invalidate(trashItemsProvider);
}
