import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart'
    show trashRetention;

/// Stores pages deleted from a document so they can be restored later.
abstract class PageTrashRepository {
  /// Trashed pages, newest first.
  Future<List<TrashedPage>> getTrashedPages();

  /// Moves [pageData] (page [pageIndex] of [documentId]) to the trash and
  /// returns the id of the new trash entry.
  Future<String> movePageToTrash({
    required String documentId,
    required String documentTitle,
    required int pageIndex,
    required Map<String, dynamic> pageData,
  });

  /// Re-inserts the page into its document. Returns false when the trashed
  /// page or its document no longer exists.
  Future<bool> restorePageFromTrash(String trashedPageId);

  /// Removes the page from the trash for good.
  Future<void> permanentlyDeletePage(String trashedPageId);

  /// Removes every trashed page for good; returns how many.
  Future<int> emptyTrash();

  /// Removes trashed pages deleted before `now - retention`; returns how many.
  Future<int> purgeExpired({
    required DateTime now,
    Duration retention = trashRetention,
  });

  /// Whether the source document of a trashed page still exists.
  Future<bool> documentExists(String documentId);
}
