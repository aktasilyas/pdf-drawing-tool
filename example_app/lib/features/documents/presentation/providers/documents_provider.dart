import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';

// Repository provider using GetIt
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return GetIt.instance<DocumentRepository>();
});

// Current folder ID
final currentFolderIdProvider = StateProvider<String?>((ref) => null);

// View mode (grid/list) with persistence
final viewModeProvider = StateNotifierProvider<ViewModeNotifier, ViewMode>((ref) {
  return ViewModeNotifier();
});

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier() : super(ViewMode.grid) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.viewMode);
    if (value != null) {
      final mode = ViewMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ViewMode.grid,
      );
      state = mode;
    }
  }

  Future<void> set(ViewMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.viewMode, mode.name);
  }
}

// Sort option (date/name/size) with persistence
final sortOptionProvider = StateNotifierProvider<SortOptionNotifier, SortOption>((ref) {
  return SortOptionNotifier();
});

class SortOptionNotifier extends StateNotifier<SortOption> {
  SortOptionNotifier() : super(SortOption.date) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.sortOption);
    if (value != null) {
      final option = SortOption.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SortOption.date,
      );
      state = option;
    }
  }

  Future<void> set(SortOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.sortOption, option.name);
  }
}

// Sort direction (ascending/descending) with persistence
final sortDirectionProvider = StateNotifierProvider<SortDirectionNotifier, SortDirection>((ref) {
  return SortDirectionNotifier();
});

class SortDirectionNotifier extends StateNotifier<SortDirection> {
  SortDirectionNotifier() : super(SortDirection.descending) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.sortDirection);
    if (value != null) {
      final direction = SortDirection.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SortDirection.descending,
      );
      state = direction;
    }
  }

  Future<void> set(SortDirection direction) async {
    state = direction;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.sortDirection, direction.name);
  }
}

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
    String? coverId,
    bool hasCover = true,
    double paperWidthMm = 210.0,
    double paperHeightMm = 297.0,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.createDocument(
      title: title,
      templateId: templateId,
      folderId: folderId,
      paperColor: paperColor,
      isPortrait: isPortrait,
      documentType: documentType,
      coverId: coverId,
      hasCover: hasCover,
      paperWidthMm: paperWidthMm,
      paperHeightMm: paperHeightMm,
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

  /// Create document with pre-rendered pages (for PDF import).
  Future<String?> createDocumentWithPages({
    required String title,
    String? folderId,
    required DocumentType documentType,
    required List<Map<String, dynamic>> pages,
    required int pageCount,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      // 1. İlk olarak doküman oluştur (blank template ile)
      final result = await _repository.createDocument(
        title: title,
        templateId: 'blank', // PDF için template gereksiz
        folderId: folderId,
        paperColor: 'Beyaz kağıt', // PDF için varsayılan
        isPortrait: true,
        documentType: documentType,
      );
      
      return result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
          return null;
        },
        (document) async {
          // 2. JSON'u encode/decode ederek tip tutarlılığını sağla
          // Bu sayede int/double/String karışıklığı önlenir
          final jsonString = jsonEncode(pages);
          final normalizedPages = jsonDecode(jsonString) as List;
          
          // 3. V2 format için complete document structure oluştur
          final now = DateTime.now();
          final content = {
            'version': 2, // V2 format (int olarak)
            'id': document.id,
            'title': document.title,
            'pages': normalizedPages,
            'currentPageIndex': 0,
            'settings': {
              'defaultPageSize': {
                'width': 595.0,
                'height': 842.0,
                'preset': 'a4Portrait',
              },
              'defaultBackground': {
                'type': 'blank',
                'color': 4294967295, // 0xFFFFFFFF (white)
              },
            },
            'documentType': documentType.name,
            'createdAt': document.createdAt.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          };
          
          final saveResult = await _repository.saveDocumentContent(
            id: document.id,
            content: content,
            pageCount: pageCount,
          );
          
          return saveResult.fold(
            (failure) {
              state = AsyncValue.error(failure, StackTrace.current);
              return null;
            },
            (_) {
              state = const AsyncValue.data(null);
              _invalidateDocuments();
              return document.id;
            },
          );
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
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
