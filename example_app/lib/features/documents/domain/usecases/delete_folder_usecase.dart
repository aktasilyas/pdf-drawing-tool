import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/repositories/folder_repository.dart';

@injectable
class DeleteFolderUseCase {
  final FolderRepository _repository;

  DeleteFolderUseCase(this._repository);

  /// Returns how many notes were moved to the trash.
  Future<Either<Failure, int>> call(
    String id, {
    bool deleteContents = false,
  }) {
    return _repository.deleteFolder(id, deleteContents: deleteContents);
  }
}
