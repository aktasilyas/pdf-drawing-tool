import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import '../repositories/folder_repository.dart';

@injectable
class DeleteFolderUseCase {
  final FolderRepository _repository;

  DeleteFolderUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String id, {
    bool deleteContents = false,
  }) {
    return _repository.deleteFolder(id, deleteContents: deleteContents);
  }
}
