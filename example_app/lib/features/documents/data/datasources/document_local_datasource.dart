import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';

abstract class DocumentLocalDatasource {
  Future<List<DocumentModel>> getDocuments({String? folderId});
  Future<List<DocumentModel>> getAllDocuments(); // Get ALL documents regardless of folder
  Future<DocumentModel> getDocument(String id);
  Future<DocumentModel> createDocument(DocumentModel document);
  Future<DocumentModel> updateDocument(DocumentModel document);
  Future<void> deleteDocument(String id);
  Stream<List<DocumentModel>> watchDocuments({String? folderId});
  Future<Map<String, dynamic>?> getDocumentContent(String id);
  Future<void> saveDocumentContent(String id, Map<String, dynamic> content);
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
        // Return only documents without a folder (root level)
        return documents.where((doc) => doc.folderId == null).toList();
      }

      return documents.where((doc) => doc.folderId == folderId).toList();
    } catch (e) {
      throw CacheException('Failed to get documents: $e');
    }
  }

  @override
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final jsonString = _prefs.getString(_documentsKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get all documents: $e');
    }
  }

  @override
  Future<DocumentModel> getDocument(String id) async {
    try {
      // Get ALL documents (not filtered by folderId)
      final documents = await getAllDocuments();
      return documents.firstWhere(
        (doc) => doc.id == id,
        orElse: () => throw const CacheException('Document not found'),
      );
    } catch (e) {
      throw CacheException('Failed to get document: $e');
    }
  }

  @override
  Future<DocumentModel> createDocument(DocumentModel document) async {
    try {
      // Get ALL documents (not filtered by folderId)
      final documents = await getAllDocuments();
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
      // Get ALL documents (not filtered by folderId)
      final documents = await getAllDocuments();
      final index = documents.indexWhere((doc) => doc.id == document.id);
      
      if (index == -1) {
        throw const CacheException('Document not found');
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
      // Get ALL documents (not filtered by folderId)
      final documents = await getAllDocuments();
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
      // Return only documents without a folder (root level)
      return _controller.stream.map(
        (documents) => documents.where((doc) => doc.folderId == null).toList(),
      );
    }

    return _controller.stream.map(
      (documents) => documents.where((doc) => doc.folderId == folderId).toList(),
    );
  }

  @override
  Future<Map<String, dynamic>?> getDocumentContent(String id) async {
    try {
      final key = 'document_content_$id';
      final jsonString = _prefs.getString(key);
      if (jsonString == null) {
        return null;
      }
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw CacheException('Failed to get document content: $e');
    }
  }

  @override
  Future<void> saveDocumentContent(String id, Map<String, dynamic> content) async {
    try {
      final key = 'document_content_$id';
      final jsonString = json.encode(content);
      await _prefs.setString(key, jsonString);
    } catch (e) {
      throw CacheException('Failed to save document content: $e');
    }
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
