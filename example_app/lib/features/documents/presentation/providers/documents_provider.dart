import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';

// Repository provider using GetIt
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return GetIt.instance<DocumentRepository>();
});

// Current folder ID
final currentFolderIdProvider = StateProvider<String?>((ref) => null);

// View mode (grid/list)
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Documents list
final documentsProvider = FutureProvider.family<List<DocumentInfo>, String?>((ref, folderId) async {
  final repository = ref.watch(documentRepositoryProvider);
  final result = await repository.getDocuments(folderId: folderId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (documents) => documents,
  );
});

// Favorite documents
final favoriteDocumentsProvider = FutureProvider<List<DocumentInfo>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final result = await repository.getFavorites();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (documents) => documents,
  );
});

// Recent documents
final recentDocumentsProvider = FutureProvider<List<DocumentInfo>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final result = await repository.getRecent(limit: 10);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (documents) => documents,
  );
});

// Trash documents
final trashDocumentsProvider = FutureProvider<List<DocumentInfo>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final result = await repository.getTrash();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (documents) => documents,
  );
});

// Search results
final searchResultsProvider = FutureProvider<List<DocumentInfo>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  final repository = ref.watch(documentRepositoryProvider);
  final result = await repository.search(query);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (documents) => documents,
  );
});

// Documents controller for mutations
class DocumentsController extends StateNotifier<AsyncValue<void>> {
  final DocumentRepository _repository;
  final Ref _ref;

  DocumentsController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<String?> createDocument({
    required String title,
    required String templateId,
    String? folderId,
    String paperColor = 'Sarı kağıt',
    bool isPortrait = true,
    DocumentType documentType = DocumentType.notebook,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.createDocument(
      title: title,
      templateId: templateId,
      folderId: folderId,
      paperColor: paperColor,
      isPortrait: isPortrait,
      documentType: documentType,
    );
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return null;
      },
      (document) {
        state = const AsyncValue.data(null);
        _invalidateDocuments();
        return document.id;
      },
    );
  }

  Future<bool> moveDocument(String documentId, String? targetFolderId) async {
    state = const AsyncValue.loading();
    final result = await _repository.moveDocument(documentId, targetFolderId);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        _invalidateDocuments();
        return true;
      },
    );
  }

  Future<bool> toggleFavorite(String documentId) async {
    final result = await _repository.toggleFavorite(documentId);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateDocuments();
        return true;
      },
    );
  }

  Future<bool> moveToTrash(String documentId) async {
    final result = await _repository.moveToTrash(documentId);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateDocuments();
        return true;
      },
    );
  }

  Future<bool> restoreFromTrash(String documentId) async {
    final result = await _repository.restoreFromTrash(documentId);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateDocuments();
        return true;
      },
    );
  }

  Future<bool> deleteDocument(String documentId) async {
    final result = await _repository.deleteDocument(documentId);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateDocuments();
        return true;
      },
    );
  }

  Future<bool> renameDocument(String documentId, String newTitle) async {
    final result = await _repository.updateDocument(id: documentId, title: newTitle);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateDocuments();
        return true;
      },
    );
  }

  void _invalidateDocuments() {
    _ref.invalidate(documentsProvider);
    _ref.invalidate(favoriteDocumentsProvider);
    _ref.invalidate(recentDocumentsProvider);
    _ref.invalidate(trashDocumentsProvider);
  }
}

final documentsControllerProvider = StateNotifierProvider<DocumentsController, AsyncValue<void>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentsController(repository, ref);
});
