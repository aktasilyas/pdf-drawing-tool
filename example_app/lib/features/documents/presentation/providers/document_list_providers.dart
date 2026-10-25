import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';

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

// Documents list
final documentsProvider =
    FutureProvider.family<List<DocumentInfo>, String?>((ref, folderId) async {
  final repository = ref.watch(documentRepositoryProvider);
  final result = await repository.getDocuments(folderId: folderId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (documents) => documents,
  );
});

// Favorite documents
final favoriteDocumentsProvider =
    FutureProvider<List<DocumentInfo>>((ref) async {
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
