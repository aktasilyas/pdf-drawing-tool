import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_content_codec.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';

abstract class DocumentLocalDatasource {
  Future<List<DocumentModel>> getDocuments({String? folderId});
  Future<List<DocumentModel>>
      getAllDocuments(); // Get ALL documents regardless of folder
  Future<DocumentModel> getDocument(String id);
  Future<DocumentModel> createDocument(DocumentModel document);
  Future<DocumentModel> updateDocument(DocumentModel document);
  Future<void> deleteDocument(String id);
  Stream<List<DocumentModel>> watchDocuments({String? folderId});
  Future<Map<String, dynamic>?> getDocumentContent(String id);
  Future<void> saveDocumentContent(String id, Map<String, dynamic> content);

  /// Whether a content row exists for [id] (without decoding it).
  Future<bool> hasDocumentContent(String id);
}

/// Drift-backed document metadata and content storage.
@Injectable(as: DocumentLocalDatasource)
class DocumentLocalDatasourceImpl implements DocumentLocalDatasource {
  final AppDatabase _db;
  final DocumentContentCodec _codec;
  final PdfPathResolver _pdfPaths;

  /// Newest content write per document. Large encodes yield mid-way, so
  /// writes are chained to land in call order (a stale autosave never
  /// overwrites a newer save).
  final Map<String, Future<void>> _contentWrites = {};

  DocumentLocalDatasourceImpl(
    this._db, {
    DocumentContentCodec codec = const DocumentContentCodec(),
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  })  : _codec = codec,
        _pdfPaths = pdfPaths;

  /// Root level (folderId null) or a single folder.
  SimpleSelectStatement<$DocumentsTable, DocumentRow> _folderQuery(
    String? folderId,
  ) {
    return _db.select(_db.documents)
      ..where(
        (t) => folderId == null
            ? t.folderId.isNull()
            : t.folderId.equals(folderId),
      );
  }

  @override
  Future<List<DocumentModel>> getDocuments({String? folderId}) async {
    try {
      final rows = await _folderQuery(folderId).get();
      return rows.map(_toModel).toList();
    } catch (e) {
      throw CacheException('Failed to get documents: $e');
    }
  }

  @override
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final rows = await _db.select(_db.documents).get();
      return rows.map(_toModel).toList();
    } catch (e) {
      throw CacheException('Failed to get all documents: $e');
    }
  }

  @override
  Future<DocumentModel> getDocument(String id) async {
    try {
      final row = await (_db.select(_db.documents)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) throw const CacheException('Document not found');
      return _toModel(row);
    } catch (e) {
      throw CacheException('Failed to get document: $e');
    }
  }

  @override
  Future<DocumentModel> createDocument(DocumentModel document) async {
    try {
      await _db.into(_db.documents).insert(_toCompanion(document));
      return document;
    } catch (e) {
      throw CacheException('Failed to create document: $e');
    }
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    try {
      final count = await (_db.update(_db.documents)
            ..where((t) => t.id.equals(document.id)))
          .write(_toCompanion(document));
      if (count == 0) throw const CacheException('Document not found');
      return document;
    } catch (e) {
      throw CacheException('Failed to update document: $e');
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      final orphans = await _db.transaction(() async {
        final paths = await _pdfPathsOf(id);
        await (_db.delete(_db.trashedPages)
              ..where((t) => t.sourceDocumentId.equals(id)))
            .go();
        await (_db.delete(_db.documentContents)
              ..where((t) => t.documentId.equals(id)))
            .go();
        await (_db.delete(_db.documents)..where((t) => t.id.equals(id))).go();
        return [
          for (final path in paths)
            if (!await _isPdfReferenced(path)) path,
        ];
      });
      for (final path in orphans) {
        await _deleteFile(path);
      }
    } catch (e) {
      throw CacheException('Failed to delete document: $e');
    }
  }

  /// Copied PDF files the stored pages of [id] point to.
  Future<Set<String>> _pdfPathsOf(String id) async {
    final row = await (_db.select(_db.documentContents)
          ..where((t) => t.documentId.equals(id)))
        .getSingleOrNull();
    if (row == null) return {};
    final pages = (await _codec.decode(row.data))['pages'];
    if (pages is! List) return {};
    return {
      for (final page in pages)
        if (page is Map && page['background'] is Map)
          if ((page['background'] as Map)['pdfFilePath'] case final String p) p,
    };
  }

  /// Whether any remaining document content or trashed page mentions [path].
  Future<bool> _isPdfReferenced(String path) async {
    final needle = json.encode(path);
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

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(_pdfPaths.resolve(path));
      if (await file.exists()) await file.delete();
    } catch (e) {
      logger.w('Could not delete PDF copy $path: $e');
    }
  }

  @override
  Stream<List<DocumentModel>> watchDocuments({String? folderId}) {
    return _folderQuery(folderId)
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  @override
  Future<Map<String, dynamic>?> getDocumentContent(String id) async {
    try {
      final row = await (_db.select(_db.documentContents)
            ..where((t) => t.documentId.equals(id)))
          .getSingleOrNull();
      if (row == null) return null;
      return await _codec.decode(row.data);
    } catch (e) {
      throw CacheException('Failed to get document content: $e');
    }
  }

  @override
  Future<void> saveDocumentContent(
    String id,
    Map<String, dynamic> content,
  ) {
    final write = _writeContentAfter(_contentWrites[id], id, content);
    _contentWrites[id] = write;
    unawaited(
      write.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
        if (identical(_contentWrites[id], write)) _contentWrites.remove(id);
      }),
    );
    return write;
  }

  Future<void> _writeContentAfter(
    Future<void>? previous,
    String id,
    Map<String, dynamic> content,
  ) async {
    if (previous != null) {
      try {
        await previous;
      } catch (_) {
        // Already reported to the caller of that save.
      }
    }
    try {
      final data = await _codec.encode(content);
      await _db.into(_db.documentContents).insertOnConflictUpdate(
            DocumentContentsCompanion(
              documentId: Value(id),
              data: Value(data),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      throw CacheException('Failed to save document content: $e');
    }
  }

  @override
  Future<bool> hasDocumentContent(String id) async {
    try {
      final row = await (_db.selectOnly(_db.documentContents)
            ..addColumns([_db.documentContents.documentId])
            ..where(_db.documentContents.documentId.equals(id)))
          .getSingleOrNull();
      return row != null;
    } catch (e) {
      throw CacheException('Failed to check document content: $e');
    }
  }

  DocumentModel _toModel(DocumentRow r) => DocumentModel(
        id: r.id,
        title: r.title,
        folderId: r.folderId,
        templateId: r.templateId,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        thumbnailPath: r.thumbnailPath,
        pageCount: r.pageCount,
        isFavorite: r.isFavorite,
        isInTrash: r.isInTrash,
        deletedAt: r.deletedAt,
        syncState: r.syncState,
        paperColor: r.paperColor,
        isPortrait: r.isPortrait,
        documentType: r.documentType,
        coverId: r.coverId,
        hasCover: r.hasCover,
        paperWidthMm: r.paperWidthMm,
        paperHeightMm: r.paperHeightMm,
      );

  DocumentsCompanion _toCompanion(DocumentModel d) => DocumentsCompanion(
        id: Value(d.id),
        title: Value(d.title),
        folderId: Value(d.folderId),
        templateId: Value(d.templateId),
        createdAt: Value(d.createdAt),
        updatedAt: Value(d.updatedAt),
        thumbnailPath: Value(d.thumbnailPath),
        pageCount: Value(d.pageCount),
        isFavorite: Value(d.isFavorite),
        isInTrash: Value(d.isInTrash),
        deletedAt: Value(d.deletedAt),
        syncState: Value(d.syncState),
        paperColor: Value(d.paperColor),
        isPortrait: Value(d.isPortrait),
        documentType: Value(d.documentType),
        coverId: Value(d.coverId),
        hasCover: Value(d.hasCover),
        paperWidthMm: Value(d.paperWidthMm),
        paperHeightMm: Value(d.paperHeightMm),
      );
}
