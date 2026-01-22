import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/core.dart';
import '../models/document_model.dart';

abstract class DocumentLocalDatasource {
  Future<List<DocumentModel>> getDocuments({String? folderId});
  Future<DocumentModel> getDocument(String id);
  Future<DocumentModel> createDocument(DocumentModel document);
  Future<DocumentModel> updateDocument(DocumentModel document);
  Future<void> deleteDocument(String id);
  Stream<List<DocumentModel>> watchDocuments({String? folderId});
}

@Injectable(as: DocumentLocalDatasource)
class DocumentLocalDatasourceImpl implements DocumentLocalDatasource {
  static const String _documentsKey = 'documents';
  final SharedPreferences _prefs;
  final StreamController<List<DocumentModel>> _controller =
      StreamController<List<DocumentModel>>.broadcast();

  DocumentLocalDatasourceImpl(this._prefs);

  @override
  Future<List<DocumentModel>> getDocuments({String? folderId}) async {
    try {
      final jsonString = _prefs.getString(_documentsKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString) as List;
      final documents = jsonList
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (folderId == null) {
        return documents;
      }

      return documents.where((doc) => doc.folderId == folderId).toList();
    } catch (e) {
      throw CacheException('Failed to get documents: $e');
    }
  }

  @override
  Future<DocumentModel> getDocument(String id) async {
    try {
      final documents = await getDocuments();
      return documents.firstWhere(
        (doc) => doc.id == id,
        orElse: () => throw CacheException('Document not found'),
      );
    } catch (e) {
      throw CacheException('Failed to get document: $e');
    }
  }

  @override
  Future<DocumentModel> createDocument(DocumentModel document) async {
    try {
      final documents = await getDocuments();
      documents.add(document);
      await _saveDocuments(documents);
      _controller.add(documents);
      return document;
    } catch (e) {
      throw CacheException('Failed to create document: $e');
    }
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    try {
      final documents = await getDocuments();
      final index = documents.indexWhere((doc) => doc.id == document.id);
      
      if (index == -1) {
        throw CacheException('Document not found');
      }

      documents[index] = document;
      await _saveDocuments(documents);
      _controller.add(documents);
      return document;
    } catch (e) {
      throw CacheException('Failed to update document: $e');
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      final documents = await getDocuments();
      documents.removeWhere((doc) => doc.id == id);
      await _saveDocuments(documents);
      _controller.add(documents);
    } catch (e) {
      throw CacheException('Failed to delete document: $e');
    }
  }

  @override
  Stream<List<DocumentModel>> watchDocuments({String? folderId}) {
    // Emit initial data
    getDocuments(folderId: folderId).then((docs) {
      if (!_controller.isClosed) {
        _controller.add(docs);
      }
    });

    if (folderId == null) {
      return _controller.stream;
    }

    return _controller.stream.map(
      (documents) => documents.where((doc) => doc.folderId == folderId).toList(),
    );
  }

  Future<void> _saveDocuments(List<DocumentModel> documents) async {
    try {
      final jsonList = documents.map((doc) => doc.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs.setString(_documentsKey, jsonString);
    } catch (e) {
      throw CacheException('Failed to save documents: $e');
    }
  }

  void dispose() {
    _controller.close();
  }
}
