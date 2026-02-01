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
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';

// Repository provider using GetIt
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return GetIt.instance<DocumentRepository>();
});

// Current folder ID
final currentFolderIdProvider = StateProvider<String?>((ref) => null);

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Selection mode
final selectionModeProvider = StateProvider<bool>((ref) => false);

// Selected documents (Set of document IDs)
final selectedDocumentsProvider = StateProvider<Set<String>>((ref) => {});

// Selected folders for multi-selection
final selectedFoldersProvider = StateProvider<Set<String>>((ref) => {});

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
        // Only invalidate favorites and the documents list
        _invalidateSpecific(documents: true, favorites: true);
        return true;
      },
    );
  }

  Future<bool> moveToTrash(String documentId) async {
    final result = await _repository.moveToTrash(documentId);
    return result.fold(
      (failure) => false,
      (_) {
        // Invalidate documents, trash, and folders (for counts)
        _invalidateSpecific(documents: true, trash: true, folders: true);
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
        // Only invalidate documents list (rename doesn't affect favorites/trash)
        _invalidateSpecific(documents: true);
        return true;
      },
    );
  }

  void _invalidateDocuments() {
    _ref.invalidate(documentsProvider);
    _ref.invalidate(favoriteDocumentsProvider);
    _ref.invalidate(recentDocumentsProvider);
    _ref.invalidate(trashDocumentsProvider);
    _ref.invalidate(foldersProvider); // Folder counts need refresh too!
  }

  /// Invalidate only specific providers based on the operation
  void _invalidateSpecific({
    bool documents = false,
    bool favorites = false,
    bool recent = false,
    bool trash = false,
    bool folders = false,
  }) {
    if (documents) _ref.invalidate(documentsProvider);
    if (favorites) _ref.invalidate(favoriteDocumentsProvider);
    if (recent) _ref.invalidate(recentDocumentsProvider);
    if (trash) _ref.invalidate(trashDocumentsProvider);
    if (folders) _ref.invalidate(foldersProvider);
  }

  // Bulk move to trash (soft delete)
  Future<void> moveDocumentsToTrash(List<String> ids) async {
    state = const AsyncLoading();
    try {
      for (final id in ids) {
        final result = await _repository.moveToTrash(id);
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
      }
      // Invalidate documents, trash, and folders
      _invalidateSpecific(documents: true, trash: true, folders: true);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // Bulk permanent delete (hard delete) - for trash only
  Future<void> permanentlyDeleteDocuments(List<String> ids) async {
    state = const AsyncLoading();
    try {
      for (final id in ids) {
        final result = await _repository.permanentlyDelete(id);
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
      }
      // Only trash needs refresh for permanent delete
      _invalidateSpecific(trash: true);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // Legacy method - kept for backward compatibility but deprecated
  @Deprecated('Use moveDocumentsToTrash or permanentlyDeleteDocuments instead')
  Future<void> deleteDocuments(List<String> ids) async {
    return moveDocumentsToTrash(ids);
  }

  // Bulk duplicate documents
  Future<void> duplicateDocuments(List<String> ids) async {
    state = const AsyncLoading();
    try {
      for (final id in ids) {
        final result = await _repository.duplicateDocument(id);
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
      }
      _invalidateDocuments();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // Single document restore from trash
  Future<bool> restoreFromTrash(String id) async {
    try {
      final result = await _repository.restoreFromTrash(id);
      return result.fold(
        (failure) {
          state = AsyncError(failure, StackTrace.current);
          return false;
        },
        (_) {
          // Invalidate documents, trash, and folders
          _invalidateSpecific(documents: true, trash: true, folders: true);
          return true;
        },
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  // Single document duplicate
  Future<bool> duplicateDocument(String id) async {
    try {
      final result = await _repository.duplicateDocument(id);
      return result.fold(
        (failure) {
          state = AsyncError(failure, StackTrace.current);
          return false;
        },
        (_) {
          _invalidateDocuments();
          return true;
        },
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  // Single document permanent delete
  Future<bool> permanentlyDeleteDocument(String id) async {
    try {
      final result = await _repository.permanentlyDelete(id);
      return result.fold(
        (failure) {
          state = AsyncError(failure, StackTrace.current);
          return false;
        },
        (_) {
          // Only trash needs refresh for permanent delete
          _invalidateSpecific(trash: true);
          return true;
        },
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  // Move documents to folder (bulk)
  Future<bool> moveDocumentsToFolder(List<String> docIds, String? folderId) async {
    state = const AsyncLoading();
    try {
      for (final id in docIds) {
        final result = await _repository.updateDocument(
          id: id,
          folderId: folderId,
        );
        result.fold(
          (failure) {
            throw Exception(failure.message);
          },
          (_) {},
        );
      }
      _invalidateDocuments();
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final documentsControllerProvider = StateNotifierProvider<DocumentsController, AsyncValue<void>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentsController(repository, ref);
});
