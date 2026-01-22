import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:example_app/core/core.dart';
import '../../domain/entities/document_info.dart';
import '../../domain/usecases/create_document_usecase.dart';
import '../../domain/usecases/delete_document_usecase.dart';
import '../../domain/usecases/get_documents_usecase.dart';
import '../../domain/usecases/get_favorites_usecase.dart';
import '../../domain/usecases/get_recent_usecase.dart';
import '../../domain/usecases/get_trash_usecase.dart';
import '../../domain/usecases/move_document_usecase.dart';
import '../../domain/usecases/move_to_trash_usecase.dart';
import '../../domain/usecases/restore_from_trash_usecase.dart';
import '../../domain/usecases/search_documents_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';

part 'documents_provider.g.dart';

@riverpod
class Documents extends _$Documents {
  @override
  Future<List<DocumentInfo>> build({String? folderId}) async {
    final useCase = ref.read(getDocumentsUseCaseProvider);
    final result = await useCase(folderId: folderId);
    
    return result.fold(
      (failure) => throw failure,
      (documents) => documents,
    );
  }

  Future<void> createDocument({
    required String title,
    required String templateId,
    String? folderId,
  }) async {
    final useCase = ref.read(createDocumentUseCaseProvider);
    final result = await useCase(
      title: title,
      templateId: templateId,
      folderId: folderId,
    );

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> moveDocument(String id, String? folderId) async {
    final useCase = ref.read(moveDocumentUseCaseProvider);
    final result = await useCase(id, folderId);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> toggleFavorite(String id) async {
    final useCase = ref.read(toggleFavoriteUseCaseProvider);
    final result = await useCase(id);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> moveToTrash(String id) async {
    final useCase = ref.read(moveToTrashUseCaseProvider);
    final result = await useCase(id);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> deleteDocument(String id) async {
    final useCase = ref.read(deleteDocumentUseCaseProvider);
    final result = await useCase(id);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class FavoriteDocuments extends _$FavoriteDocuments {
  @override
  Future<List<DocumentInfo>> build() async {
    final useCase = ref.read(getFavoritesUseCaseProvider);
    final result = await useCase();
    
    return result.fold(
      (failure) => throw failure,
      (documents) => documents,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class RecentDocuments extends _$RecentDocuments {
  @override
  Future<List<DocumentInfo>> build({int limit = 10}) async {
    final useCase = ref.read(getRecentUseCaseProvider);
    final result = await useCase(limit: limit);
    
    return result.fold(
      (failure) => throw failure,
      (documents) => documents,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class TrashDocuments extends _$TrashDocuments {
  @override
  Future<List<DocumentInfo>> build() async {
    final useCase = ref.read(getTrashUseCaseProvider);
    final result = await useCase();
    
    return result.fold(
      (failure) => throw failure,
      (documents) => documents,
    );
  }

  Future<void> restoreFromTrash(String id) async {
    final useCase = ref.read(restoreFromTrashUseCaseProvider);
    final result = await useCase(id);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class SearchDocuments extends _$SearchDocuments {
  @override
  Future<List<DocumentInfo>> build(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final useCase = ref.read(searchDocumentsUseCaseProvider);
    final result = await useCase(query);
    
    return result.fold(
      (failure) => throw failure,
      (documents) => documents,
    );
  }
}

// View mode state
enum ViewMode { grid, list }

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

// Current folder state
final currentFolderIdProvider = StateProvider<String?>((ref) => null);

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Use case providers
@riverpod
GetDocumentsUseCase getDocumentsUseCase(GetDocumentsUseCaseRef ref) {
  return ref.watch(getItProvider).get<GetDocumentsUseCase>();
}

@riverpod
CreateDocumentUseCase createDocumentUseCase(CreateDocumentUseCaseRef ref) {
  return ref.watch(getItProvider).get<CreateDocumentUseCase>();
}

@riverpod
DeleteDocumentUseCase deleteDocumentUseCase(DeleteDocumentUseCaseRef ref) {
  return ref.watch(getItProvider).get<DeleteDocumentUseCase>();
}

@riverpod
MoveDocumentUseCase moveDocumentUseCase(MoveDocumentUseCaseRef ref) {
  return ref.watch(getItProvider).get<MoveDocumentUseCase>();
}

@riverpod
ToggleFavoriteUseCase toggleFavoriteUseCase(ToggleFavoriteUseCaseRef ref) {
  return ref.watch(getItProvider).get<ToggleFavoriteUseCase>();
}

@riverpod
GetFavoritesUseCase getFavoritesUseCase(GetFavoritesUseCaseRef ref) {
  return ref.watch(getItProvider).get<GetFavoritesUseCase>();
}

@riverpod
GetRecentUseCase getRecentUseCase(GetRecentUseCaseRef ref) {
  return ref.watch(getItProvider).get<GetRecentUseCase>();
}

@riverpod
SearchDocumentsUseCase searchDocumentsUseCase(SearchDocumentsUseCaseRef ref) {
  return ref.watch(getItProvider).get<SearchDocumentsUseCase>();
}

@riverpod
GetTrashUseCase getTrashUseCase(GetTrashUseCaseRef ref) {
  return ref.watch(getItProvider).get<GetTrashUseCase>();
}

@riverpod
MoveToTrashUseCase moveToTrashUseCase(MoveToTrashUseCaseRef ref) {
  return ref.watch(getItProvider).get<MoveToTrashUseCase>();
}

@riverpod
RestoreFromTrashUseCase restoreFromTrashUseCase(
  RestoreFromTrashUseCaseRef ref,
) {
  return ref.watch(getItProvider).get<RestoreFromTrashUseCase>();
}

// GetIt provider (should exist in core)
final getItProvider = Provider<GetIt>((ref) => GetIt.instance);
