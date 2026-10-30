import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/datasources/managed_file_paths.dart';

/// Library thumbnail storage of [DocumentRepositoryImpl].
mixin DocumentThumbnails {
  DocumentLocalDatasource get localDatasource;

  /// Resolves stored thumbnail paths; passthrough when there is no root.
  PdfPathResolver get thumbnailPaths;

  /// Runs [action] in one transaction and maps errors to a [Failure].
  Future<Either<Failure, T>> guard<T>(
    String what,
    Future<T> Function() action,
  );

  Future<Either<Failure, String>> saveThumbnail(
    String id,
    Uint8List png,
  ) async {
    final root = thumbnailPaths.documentsRoot;
    if (root == null || root.isEmpty) {
      return const Left(CacheFailure('No documents root'));
    }
    final stored = '${PdfPathResolver.imagesDir}/'
        'thumb_${id}_${DateTime.now().microsecondsSinceEpoch}.png';
    final file = File(thumbnailPaths.resolve(stored));
    // File I/O stays outside the transaction.
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png, flush: true);
    } on FileSystemException catch (e) {
      return Left(CacheFailure('Failed to write thumbnail: ${e.message}'));
    }

    final result = await guard<String?>('save thumbnail', () async {
      final doc = await localDatasource.getDocument(id);
      // copyWith keeps updatedAt and folderId.
      await localDatasource.updateDocument(doc.copyWith(thumbnailPath: stored));
      return doc.thumbnailPath;
    });

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      await _deleteQuietly(file);
      return Left(failure);
    }
    final previous = result.getOrElse(() => null);
    // A legacy value may point at the user's own file: only managed
    // thumbnails are ever deleted.
    if (previous != null &&
        previous != stored &&
        isManagedImagePath(previous)) {
      try {
        // A duplicate may still use the previous file; only unreferenced
        // files are deleted.
        await localDatasource.deleteUnreferencedFiles([previous]);
      } catch (e) {
        logger.w('Could not delete old thumbnail $previous: $e');
      }
    }
    return Right(stored);
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      logger.w('Could not delete thumbnail ${file.path}: $e');
    }
  }
}
