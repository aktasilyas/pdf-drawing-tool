import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart' show Failure;
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart'
    show trashRetention;

/// Stores pages deleted from a document so they can be restored later.
abstract class PageTrashRepository {
  /// Trashed pages, newest first.
  Future<Either<Failure, List<TrashedPage>>> getTrashedPages();

  /// Moves [pageData] (page [pageIndex] of [documentId]) to the trash and
  /// returns the id of the new trash entry.
  Future<Either<Failure, String>> movePageToTrash({
    required String documentId,
    required String documentTitle,
    required int pageIndex,
    required Map<String, dynamic> pageData,
  });

  /// Re-inserts the page into its document. Right(false) when the trashed
  /// page or its document no longer exists.
  Future<Either<Failure, bool>> restorePageFromTrash(String trashedPageId);

  /// Removes the page from the trash for good, and the copied PDF file it
  /// was the last reference to.
  Future<Either<Failure, void>> permanentlyDeletePage(String trashedPageId);

  /// Drops only the trash entry because its page went back into the open
  /// document (undo of a page delete). Its files are kept: the restored page
  /// may not be saved yet, so the stored content cannot vouch for them. Real
  /// orphans are reclaimed by the startup orphan sweep.
  Future<Either<Failure, void>> discardTrashedPage(String trashedPageId);

  /// Removes every trashed page for good; returns how many.
  Future<Either<Failure, int>> emptyTrash();

  /// Removes trashed pages deleted before `now - retention`; returns how many.
  Future<Either<Failure, int>> purgeExpired({
    required DateTime now,
    Duration retention = trashRetention,
  });

  /// Whether the source document of a trashed page still exists and is not
  /// in the trash, i.e. whether the page can be restored into it.
  Future<Either<Failure, bool>> documentExists(String documentId);
}
