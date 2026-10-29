import 'dart:convert';
import 'dart:io';

import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:drift/drift.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_content_codec.dart';
import 'package:example_app/features/documents/data/datasources/managed_file_paths.dart';

/// Finds and deletes the app-managed files (copied PDFs, imported images)
/// that no stored document content or trashed page references any more.
class ManagedFileCleanup {
  ManagedFileCleanup(
    this._db,
    this._codec,
    this._paths, [
    ClipboardFileRefs? clipboard,
  ]) : _clipboard = clipboard ?? ClipboardFileRefs();

  final AppDatabase _db;
  final DocumentContentCodec _codec;
  final PdfPathResolver _paths;
  final ClipboardFileRefs _clipboard;

  /// Managed files the stored pages of document [id] point to.
  Future<Set<String>> pathsOfDocument(String id) async {
    final row = await (_db.select(_db.documentContents)
          ..where((t) => t.documentId.equals(id)))
        .getSingleOrNull();
    if (row == null) return {};
    final Object? pages;
    try {
      pages = (await _codec.decode(row.data))['pages'];
    } catch (e) {
      // Undecodable content must not block deletion; only file cleanup is lost.
      logger.w('Skipping file cleanup, content of $id is corrupt: $e');
      return {};
    }
    if (pages is! List) return {};
    return {
      for (final page in pages)
        if (page is Map<String, dynamic>) ...managedFilePathsOfPage(page),
    };
  }

  /// The members of [paths] that nothing references any more.
  Future<List<String>> unreferenced(Iterable<String> paths) async {
    return [
      for (final path in paths.toSet())
        if (!await _isReferenced(path)) path,
    ];
  }

  /// Whether a clipboard, any remaining document content or a trashed page
  /// mentions [path].
  Future<bool> _isReferenced(String path) async =>
      _clipboard.contains(path) || await _anyRowContains(json.encode(path));

  /// Whether any document content or trashed page mentions the file [name]
  /// anywhere (SQL `LIKE`; wildcards in [name] only widen the match).
  Future<bool> isMentioned(String name) => _anyRowContains(name);

  Future<bool> _anyRowContains(String needle) async {
    final content = await (_db.select(_db.documentContents)
          ..where((t) => t.data.contains(needle))
          ..limit(1))
        .get();
    if (content.isNotEmpty) return true;
    final pages = await (_db.select(_db.trashedPages)
          ..where((t) => t.pageData.contains(needle))
          ..limit(1))
        .get();
    return pages.isNotEmpty;
  }

  /// Best-effort delete of the stored [paths]; failures are logged.
  Future<void> deleteFiles(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(_paths.resolve(path));
        if (await file.exists()) await file.delete();
      } catch (e) {
        logger.w('Could not delete managed file $path: $e');
      }
    }
  }
}
