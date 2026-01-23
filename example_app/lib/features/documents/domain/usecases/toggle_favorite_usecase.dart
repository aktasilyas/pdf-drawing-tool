import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';

@injectable
class ToggleFavoriteUseCase {
  final DocumentRepository _repository;

  ToggleFavoriteUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.toggleFavorite(id);
  }
}
