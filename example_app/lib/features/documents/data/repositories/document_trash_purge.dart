import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart'
    show trashRetention;

/// Bulk trash removal of [DocumentRepositoryImpl] (empty and retention purge).
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
        await localDatasource.deleteDocument(doc.id);
        count++;
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
          await localDatasource.deleteDocument(doc.id);
          purged++;
        }
      }
      return purged;
    });
  }
}
