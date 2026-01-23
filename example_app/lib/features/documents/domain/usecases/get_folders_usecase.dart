import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/domain/repositories/folder_repository.dart';

@injectable
class GetFoldersUseCase {
  final FolderRepository _repository;

  GetFoldersUseCase(this._repository);

  Future<Either<Failure, List<Folder>>> call({String? parentId}) {
    return _repository.getFolders(parentId: parentId);
  }
}
