import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/features/documents/data/datasources/trashed_page_local_datasource.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';

class PageTrashRepository {
  final TrashedPageLocalDatasource _datasource;
  final SharedPreferences _prefs;

  PageTrashRepository(this._datasource, this._prefs);

  Future<List<TrashedPage>> getTrashedPages() async {
    final models = await _datasource.getTrashedPages();
    final entities = models.map((m) => m.toEntity()).toList();
    entities.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return entities;
  }

  Future<void> movePageToTrash({
    required String documentId,
    required String documentTitle,
    required int pageIndex,
    required Map<String, dynamic> pageData,
  }) async {
    final now = DateTime.now();
    final pageId = pageData['id'] as String? ?? 'unknown';
    final model = TrashedPageModel(
      id: 'trashed_page_${now.millisecondsSinceEpoch}',
      pageId: pageId,
      sourceDocumentId: documentId,
      sourceDocumentTitle: documentTitle,
      originalPageIndex: pageIndex,
      deletedAt: now,
      pageData: pageData,
    );
    await _datasource.addTrashedPage(model);
  }

  Future<bool> restorePageFromTrash(String trashedPageId) async {
    final model = await _datasource.getTrashedPage(trashedPageId);
    if (model == null) return false;

    // Load document content
    final key = 'document_content_${model.sourceDocumentId}';
    final contentJson = _prefs.getString(key);
    if (contentJson == null) return false;

    final content = json.decode(contentJson) as Map<String, dynamic>;
    final pages = (content['pages'] as List).cast<Map<String, dynamic>>();

    // Insert page at clamped original position
    final insertIndex = min(model.originalPageIndex, pages.length);
    pages.insert(insertIndex, model.pageData);

    // Re-index pages
    for (int i = 0; i < pages.length; i++) {
      pages[i]['index'] = i;
    }

    content['pages'] = pages;
    await _prefs.setString(key, json.encode(content));

    // Update page count in document metadata
    await _updateDocumentPageCount(model.sourceDocumentId, pages.length);

    await _datasource.removeTrashedPage(trashedPageId);
    return true;
  }

  Future<void> permanentlyDeletePage(String trashedPageId) async {
    await _datasource.removeTrashedPage(trashedPageId);
  }

  Future<bool> documentExists(String documentId) async {
    final key = 'document_content_$documentId';
    return _prefs.getString(key) != null;
  }

  Future<void> _updateDocumentPageCount(
    String documentId,
    int newCount,
  ) async {
    final docsJson = _prefs.getString('documents');
    if (docsJson == null) return;

    final List<dynamic> docs = json.decode(docsJson) as List;
    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i] as Map<String, dynamic>;
      if (doc['id'] == documentId) {
        doc['page_count'] = newCount;
        doc['updated_at'] = DateTime.now().toIso8601String();
        break;
      }
    }
    await _prefs.setString('documents', json.encode(docs));
  }
}
