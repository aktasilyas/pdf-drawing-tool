import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:example_app/core/core.dart';
import '../../domain/entities/folder.dart';
import '../../domain/usecases/create_folder_usecase.dart';
import '../../domain/usecases/delete_folder_usecase.dart';
import '../../domain/usecases/get_folders_usecase.dart';

part 'folders_provider.g.dart';

@riverpod
class Folders extends _$Folders {
  @override
  Future<List<Folder>> build({String? parentId}) async {
    final useCase = ref.read(getFoldersUseCaseProvider);
    final result = await useCase(parentId: parentId);
    
    return result.fold(
      (failure) => throw failure,
      (folders) => folders,
    );
  }

  Future<void> createFolder({
    required String name,
    String? parentId,
    int? colorValue,
  }) async {
    final useCase = ref.read(createFolderUseCaseProvider);
    final result = await useCase(
      name: name,
      parentId: parentId,
      colorValue: colorValue,
    );

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> deleteFolder(String id, {bool deleteContents = false}) async {
    final useCase = ref.read(deleteFolderUseCaseProvider);
    final result = await useCase(id, deleteContents: deleteContents);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Use case providers
@riverpod
GetFoldersUseCase getFoldersUseCase(GetFoldersUseCaseRef ref) {
  return ref.watch(getItProvider).get<GetFoldersUseCase>();
}

@riverpod
CreateFolderUseCase createFolderUseCase(CreateFolderUseCaseRef ref) {
  return ref.watch(getItProvider).get<CreateFolderUseCase>();
}

@riverpod
DeleteFolderUseCase deleteFolderUseCase(DeleteFolderUseCaseRef ref) {
  return ref.watch(getItProvider).get<DeleteFolderUseCase>();
}

// GetIt provider (should exist in core)
final getItProvider = Provider<GetIt>((ref) => GetIt.instance);
