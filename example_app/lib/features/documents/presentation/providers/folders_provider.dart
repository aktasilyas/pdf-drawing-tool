import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/domain/repositories/folder_repository.dart';

// Repository provider using GetIt
final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return GetIt.instance<FolderRepository>();
});

// All folders (root level by default)
final foldersProvider = FutureProvider<List<Folder>>((ref) async {
  final repository = ref.watch(folderRepositoryProvider);
  final result = await repository.getFolders();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (folders) => folders,
  );
});

// Folder by ID
final folderByIdProvider = FutureProvider.family<Folder?, String>((ref, folderId) async {
  final repository = ref.watch(folderRepositoryProvider);
  final result = await repository.getFolder(folderId);
  return result.fold(
    (failure) => null,
    (folder) => folder,
  );
});

// Subfolders (folders with specific parent)
final subfoldersProvider = FutureProvider.family<List<Folder>, String?>((ref, parentId) async {
  final repository = ref.watch(folderRepositoryProvider);
  final result = await repository.getFolders(parentId: parentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (folders) => folders,
  );
});

// Folder tree (hierarchical)
final folderTreeProvider = FutureProvider<List<FolderNode>>((ref) async {
  final folders = await ref.watch(foldersProvider.future);
  return _buildFolderTree(folders, null);
});

List<FolderNode> _buildFolderTree(List<Folder> allFolders, String? parentId) {
  final children = allFolders.where((f) => f.parentId == parentId).toList();
  return children.map((folder) {
    return FolderNode(
      folder: folder,
      children: _buildFolderTree(allFolders, folder.id),
    );
  }).toList();
}

class FolderNode {
  final Folder folder;
  final List<FolderNode> children;

  const FolderNode({required this.folder, required this.children});

  bool get hasChildren => children.isNotEmpty;
}

// Folders controller for mutations
class FoldersController extends StateNotifier<AsyncValue<void>> {
  final FolderRepository _repository;
  final Ref _ref;

  FoldersController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<String?> createFolder({
    required String name,
    String? parentId,
    int? colorValue,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.createFolder(
      name: name,
      parentId: parentId,
      colorValue: colorValue,
    );
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return null;
      },
      (folder) {
        state = const AsyncValue.data(null);
        _invalidateFolders();
        return folder.id;
      },
    );
  }

  Future<bool> renameFolder(String folderId, String newName) async {
    final result = await _repository.updateFolder(id: folderId, name: newName);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateFolders();
        return true;
      },
    );
  }

  Future<bool> updateFolderColor(String folderId, int colorValue) async {
    final result = await _repository.updateFolder(id: folderId, colorValue: colorValue);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateFolders();
        return true;
      },
    );
  }

  Future<bool> moveFolder({
    required String folderId,
    required String? newParentId,
  }) async {
    final result = await _repository.moveFolder(folderId, newParentId);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateFolders();
        return true;
      },
    );
  }

  Future<bool> deleteFolder(String folderId) async {
    final result = await _repository.deleteFolder(folderId);
    return result.fold(
      (failure) => false,
      (_) {
        _invalidateFolders();
        return true;
      },
    );
  }

  void _invalidateFolders() {
    _ref.invalidate(foldersProvider);
    _ref.invalidate(folderTreeProvider);
  }
}

final foldersControllerProvider = StateNotifierProvider<FoldersController, AsyncValue<void>>((ref) {
  final repository = ref.watch(folderRepositoryProvider);
  return FoldersController(repository, ref);
});
