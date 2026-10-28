import 'package:drawing_core/drawing_core.dart'
    show DrawingDocument, PageBackground, PdfPathResolver;
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_content_codec.dart';
import 'package:example_app/features/documents/data/datasources/document_content_write_queue.dart';
import 'package:example_app/features/documents/data/datasources/document_row_mapper.dart';
import 'package:example_app/features/documents/data/datasources/image_background_loader.dart';
import 'package:example_app/features/documents/data/datasources/managed_file_cleanup.dart';
import 'package:example_app/features/documents/data/datasources/managed_file_sweep.dart';
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

  /// Content of [id] as a model (decoded off the UI isolate when large), or
  /// null when there is none yet.
  Future<DrawingDocument?> getDrawingDocument(String id);

  /// Background of the first page of [id], or null when there is no content
  /// or no page. Does not build the page and stroke models.
  Future<PageBackground?> getFirstPageBackground(String id);

  /// Whether a content row exists for [id] (without decoding it).
  Future<bool> hasDocumentContent(String id);

  /// Deletes the managed files (copied PDFs, imported images) among [paths]
  /// that no document content or trashed page references any more.
  Future<void> deleteUnreferencedFiles(Iterable<String> paths);

  /// Deletes managed files that nothing references and that last changed
  /// before [olderThan]; returns how many. 0 without a documents root.
  Future<int> sweepOrphanedFiles({required DateTime olderThan});
}

/// Drift-backed document metadata and content storage.
@Injectable(as: DocumentLocalDatasource)
class DocumentLocalDatasourceImpl implements DocumentLocalDatasource {
  final AppDatabase _db;
  final DocumentContentCodec _codec;
  final PdfPathResolver _pdfPaths;
  final ManagedFileCleanup _cleanup;
  late final OrphanFileSweeper _sweeper =
      OrphanFileSweeper(_db, _cleanup, _pdfPaths);

  /// Content writes land in call order per document (a stale autosave never
  /// overwrites a newer save).
  final DocumentContentWriteQueue _contentWrites = DocumentContentWriteQueue();

  DocumentLocalDatasourceImpl(
    this._db, {
    DocumentContentCodec codec = const DocumentContentCodec(),
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  })  : _codec = codec,
        _pdfPaths = pdfPaths,
        _cleanup = ManagedFileCleanup(_db, codec, pdfPaths);

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
      return rows.map((r) => r.toModel()).toList();
    } catch (e) {
      throw CacheException('Failed to get documents: $e');
    }
  }

  @override
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final rows = await _db.select(_db.documents).get();
      return rows.map((r) => r.toModel()).toList();
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
      return row.toModel();
    } catch (e) {
      throw CacheException('Failed to get document: $e');
    }
  }

  @override
  Future<DocumentModel> createDocument(DocumentModel document) async {
    try {
      await _db.into(_db.documents).insert(document.toCompanion());
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
          .write(document.toCompanion());
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
        final paths = await _cleanup.pathsOfDocument(id);
        await (_db.delete(_db.trashedPages)
              ..where((t) => t.sourceDocumentId.equals(id)))
            .go();
        await (_db.delete(_db.documentContents)
              ..where((t) => t.documentId.equals(id)))
            .go();
        await (_db.delete(_db.documents)..where((t) => t.id.equals(id))).go();
        return _cleanup.unreferenced(paths);
      });
      await _cleanup.deleteFiles(orphans);
    } catch (e) {
      throw CacheException('Failed to delete document: $e');
    }
  }

  @override
  Future<void> deleteUnreferencedFiles(Iterable<String> paths) async {
    final List<String> orphans;
    try {
      orphans = await _cleanup.unreferenced(paths);
    } catch (e) {
      throw CacheException('Failed to check file references: $e');
    }
    await _cleanup.deleteFiles(orphans);
  }

  @override
  Future<int> sweepOrphanedFiles({required DateTime olderThan}) async {
    final root = _pdfPaths.documentsRoot;
    if (root == null || root.isEmpty) return 0;
    try {
      return await _sweeper.sweep(olderThan: olderThan);
    } catch (e) {
      throw CacheException('Failed to sweep orphaned files: $e');
    }
  }

  @override
  Stream<List<DocumentModel>> watchDocuments({String? folderId}) {
    return _folderQuery(folderId)
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
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
  Future<DrawingDocument?> getDrawingDocument(String id) async {
    final data = await _contentData(id);
    if (data == null) return null;
    try {
      final doc = await _codec.decodeDocument(data);
      return await loadImageBackgrounds(doc, _pdfPaths);
    } catch (e) {
      throw CacheException('Document corrupted: $e');
    }
  }

  @override
  Future<PageBackground?> getFirstPageBackground(String id) async {
    final data = await _contentData(id);
    if (data == null) return null;
    try {
      final json = await _codec.decodeFirstPageBackground(data);
      if (json == null) return null;
      return await loadImageBackground(
        PageBackground.fromJson(json),
        _pdfPaths,
      );
    } catch (e) {
      throw CacheException('Document corrupted: $e');
    }
  }

  /// Raw content JSON of [id], or null when no content row exists.
  Future<String?> _contentData(String id) async {
    try {
      final row = await (_db.select(_db.documentContents)
            ..where((t) => t.documentId.equals(id)))
          .getSingleOrNull();
      return row?.data;
    } catch (e) {
      throw CacheException('Failed to get document content: $e');
    }
  }

  @override
  Future<void> saveDocumentContent(
    String id,
    Map<String, dynamic> content,
  ) {
    return _contentWrites.enqueue(id, () => _writeContent(id, content));
  }

  Future<void> _writeContent(String id, Map<String, dynamic> content) async {
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
}
