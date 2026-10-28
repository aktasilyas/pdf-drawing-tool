import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/domain/repositories/page_trash_repository.dart';

/// Permanently deletes trashed documents and pages older than
/// [trashRetention]. Run once at startup; [now] is injected for tests.
class PurgeExpiredTrashUseCase {
  PurgeExpiredTrashUseCase(this._documents, this._pages);

  final DocumentRepository _documents;
  final PageTrashRepository _pages;

  /// Returns the number of purged documents and pages.
  Future<Either<Failure, int>> call(DateTime now) async {
    final documents = await _documents.purgeExpiredTrash(now: now);
    final pages = await _pages.purgeExpired(now: now);
    return documents.fold(
      (failure) => Left(failure),
      (docCount) => pages.map((pageCount) => docCount + pageCount),
    );
  }
}
