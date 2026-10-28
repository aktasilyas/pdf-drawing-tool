import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart'
    show trashRetention;

/// Bulk trash removal and orphaned-file sweep of [DocumentRepositoryImpl].
mixin DocumentTrashPurge {
  DocumentLocalDatasource get localDatasource;

  /// Runs [action] in one transaction and maps errors to a [Failure].
  Future<Either<Failure, T>> guard<T>(
    String what,
    Future<T> Function() action,
  );

  Future<Either<Failure, int>> emptyTrash() {
    return guard('empty trash', () async {
      final trashed =
          (await localDatasource.getAllDocuments()).where((d) => d.isInTrash);
      var count = 0;
      for (final doc in trashed) {
        if (await _tryDelete(doc.id)) count++;
      }
      return count;
    });
  }

  Future<Either<Failure, int>> purgeExpiredTrash({
    required DateTime now,
    Duration retention = trashRetention,
  }) {
    final cutoff = now.subtract(retention);
    return guard('purge expired trash', () async {
      var purged = 0;
      final trashed =
          (await localDatasource.getAllDocuments()).where((d) => d.isInTrash);
      for (final doc in trashed) {
        final deletedAt = doc.deletedAt;
        if (deletedAt == null) {
          // Legacy row: start its retention period now, never purge at once.
          await localDatasource.updateDocument(doc.copyWith(deletedAt: now));
        } else if (deletedAt.isBefore(cutoff)) {
          if (await _tryDelete(doc.id)) purged++;
        }
      }
      return purged;
    });
  }

  /// Not run in [guard]'s transaction: the sweep reads row by row and does
  /// file I/O, and must never hold back editor autosaves.
  Future<Either<Failure, int>> sweepOrphanedFiles({
    required DateTime olderThan,
  }) async {
    try {
      return Right(
        await localDatasource.sweepOrphanedFiles(olderThan: olderThan),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to sweep orphaned files: $e'));
    }
  }

  /// Deletes [id]; a failure is logged so one bad document never stops a bulk run.
  Future<bool> _tryDelete(String id) async {
    try {
      await localDatasource.deleteDocument(id);
      return true;
    } catch (e) {
      logger.w('Could not delete trashed document $id: $e');
      return false;
    }
  }
}
