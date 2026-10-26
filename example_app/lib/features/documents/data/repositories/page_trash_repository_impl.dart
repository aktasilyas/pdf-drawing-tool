import 'dart:math';
import 'package:example_app/core/core.dart'
    show CacheException, LocalTransactionRunner;
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/datasources/trashed_page_local_datasource.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart'
    show trashRetention;
import 'package:example_app/features/documents/domain/repositories/page_trash_repository.dart';

class PageTrashRepositoryImpl implements PageTrashRepository {
  final TrashedPageLocalDatasource _trashDatasource;
  final DocumentLocalDatasource _documentDatasource;
  final LocalTransactionRunner _runner;

  PageTrashRepositoryImpl(
    this._trashDatasource,
    this._documentDatasource,
    this._runner,
  );

  @override
  Future<List<TrashedPage>> getTrashedPages() async {
    final models = await _trashDatasource.getTrashedPages();
    final entities = models.map((m) => m.toEntity()).toList();
    entities.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return entities;
  }

  @override
  Future<String> movePageToTrash({
    required String documentId,
    required String documentTitle,
    required int pageIndex,
    required Map<String, dynamic> pageData,
  }) async {
    final now = DateTime.now();
    final pageId = pageData['id'] as String? ?? 'unknown';
    final trashId = 'trashed_page_${now.millisecondsSinceEpoch}';
    final model = TrashedPageModel(
      id: trashId,
      pageId: pageId,
      sourceDocumentId: documentId,
      sourceDocumentTitle: documentTitle,
      originalPageIndex: pageIndex,
      deletedAt: now,
      pageData: pageData,
    );
    await _trashDatasource.addTrashedPage(model);
    return trashId;
  }

  @override
  Future<bool> restorePageFromTrash(String trashedPageId) async {
    try {
      // Content, page count and trash row change together or not at all.
      return await _runner.run(() async {
        final model = await _trashDatasource.getTrashedPage(trashedPageId);
        if (model == null) return false;

        final content = await _documentDatasource
            .getDocumentContent(model.sourceDocumentId);
        if (content == null) return false;

        final pages = (content['pages'] as List).cast<Map<String, dynamic>>();

        // Insert page at clamped original position
        final insertIndex = min(model.originalPageIndex, pages.length);
        pages.insert(insertIndex, model.pageData);

        // Re-index pages
        for (int i = 0; i < pages.length; i++) {
          pages[i]['index'] = i;
        }
        content['pages'] = pages;

        await _documentDatasource.saveDocumentContent(
          model.sourceDocumentId,
          content,
        );
        await _updatePageCount(model.sourceDocumentId, pages.length);
        await _trashDatasource.removeTrashedPage(trashedPageId);
        return true;
      });
    } on CacheException {
      return false;
    }
  }

  @override
  Future<void> permanentlyDeletePage(String trashedPageId) async {
    await _trashDatasource.removeTrashedPage(trashedPageId);
  }

  @override
  Future<int> emptyTrash() async {
    final pages = await _trashDatasource.getTrashedPages();
    for (final page in pages) {
      await _trashDatasource.removeTrashedPage(page.id);
    }
    return pages.length;
  }

  @override
  Future<int> purgeExpired({
    required DateTime now,
    Duration retention = trashRetention,
  }) async {
    final cutoff = now.subtract(retention);
    final expired = (await _trashDatasource.getTrashedPages())
        .where((p) => p.deletedAt.isBefore(cutoff))
        .toList();
    for (final page in expired) {
      await _trashDatasource.removeTrashedPage(page.id);
    }
    return expired.length;
  }

  @override
  Future<bool> documentExists(String documentId) {
    return _documentDatasource.hasDocumentContent(documentId);
  }

  Future<void> _updatePageCount(String documentId, int newCount) async {
    final document = await _documentDatasource.getDocument(documentId);
    await _documentDatasource.updateDocument(
      document.copyWith(pageCount: newCount, updatedAt: DateTime.now()),
    );
  }
}
