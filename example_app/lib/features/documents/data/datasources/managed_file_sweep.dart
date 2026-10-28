import 'dart:io';
import 'dart:isolate';

import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:drift/drift.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_content_codec.dart';
import 'package:example_app/features/documents/data/datasources/managed_file_cleanup.dart';
import 'package:example_app/features/documents/data/datasources/managed_file_paths.dart';

/// Deletes managed files (copied PDFs, imported images) that no stored row
/// references: leftovers of deleted image elements, cancelled placements and
/// older leaks. Only direct file children of `<docs>/pdfs/` and
/// `<docs>/elyanotes_images/` are ever considered.
class OrphanFileSweeper {
  OrphanFileSweeper(this._db, this._cleanup, this._paths);

  final AppDatabase _db;
  final ManagedFileCleanup _cleanup;
  final PdfPathResolver _paths;

  static const _dirs = [PdfPathResolver.pdfDir, PdfPathResolver.imagesDir];

  /// Deletes the unreferenced files whose last change is before [olderThan]
  /// and returns how many were removed. A passthrough resolver (no documents
  /// root) does nothing.
  Future<int> sweep({required DateTime olderThan}) async {
    final root = _paths.documentsRoot;
    if (root == null || root.isEmpty) return 0;

    final candidates = await _candidates(root, olderThan);
    if (candidates.isEmpty) return 0;

    final referenced = await _referencedKeys();
    final orphans = <String>[];
    for (final key in candidates) {
      if (referenced.contains(key)) continue;
      // An autosave may have landed since the scan: look once more right
      // before deleting.
      if (await _cleanup.isMentioned(key.split('/').last)) continue;
      orphans.add(key);
    }
    await _cleanup.deleteFiles(orphans);
    return orphans.length;
  }

  /// `'<dir>/<name>'` of every old enough direct file child of the managed
  /// directories. Symlinks, subdirectories and other entities are skipped.
  Future<List<String>> _candidates(String root, DateTime olderThan) async {
    final keys = <String>[];
    for (final dir in _dirs) {
      final directory = Directory(_paths.resolve(dir));
      if (!await directory.exists()) continue;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          // ctime too: a copy that keeps its source mtime is still new.
          if (!stat.changed.isBefore(olderThan) ||
              !stat.modified.isBefore(olderThan)) {
            continue;
          }
          final name = entity.uri.pathSegments.last;
          // JSON escapes `"` and `\`, so a reference to such a name could not
          // be recognised: never delete it.
          if (name.contains('"') || name.contains(r'\')) continue;
          keys.add('$dir/$name');
        } catch (e) {
          logger.w('Could not inspect ${entity.path}: $e');
        }
      }
    }
    return keys;
  }

  /// Keys of every managed file that any stored row mentions. Rows are read
  /// one at a time so a large library never sits in memory at once.
  Future<Set<String>> _referencedKeys() async {
    final refs = <String>{};

    final contents = _db.documentContents;
    final contentIds = await (_db.selectOnly(contents)
          ..addColumns([contents.documentId]))
        .map((row) => row.read(contents.documentId)!)
        .get();
    for (final id in contentIds) {
      final row = await (_db.select(contents)
            ..where((t) => t.documentId.equals(id)))
          .getSingleOrNull();
      if (row != null) refs.addAll(await _refsIn(row.data));
    }

    final trashed = _db.trashedPages;
    final trashedIds = await (_db.selectOnly(trashed)..addColumns([trashed.id]))
        .map((row) => row.read(trashed.id)!)
        .get();
    for (final id in trashedIds) {
      final row = await (_db.select(trashed)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row != null) refs.addAll(await _refsIn(row.pageData));
    }

    final documents = _db.documents;
    final thumbnails = await (_db.selectOnly(documents)
          ..addColumns([documents.thumbnailPath])
          ..where(documents.thumbnailPath.isNotNull()))
        .map((row) => row.read(documents.thumbnailPath)!)
        .get();
    final messages = _db.aiMessagesLocal;
    final images = await (_db.selectOnly(messages)
          ..addColumns([messages.imagePath])
          ..where(messages.imagePath.isNotNull()))
        .map((row) => row.read(messages.imagePath)!)
        .get();
    for (final path in [...thumbnails, ...images]) {
      refs.addAll(managedFileRefsIn(path));
    }
    return refs;
  }
}

/// [managedFileRefsIn], on a background isolate for large texts.
Future<Set<String>> _refsIn(String text) {
  if (text.length < DocumentContentCodec.defaultDecodeOffloadLength) {
    return Future.value(managedFileRefsIn(text));
  }
  return Isolate.run(() => managedFileRefsIn(text));
}
