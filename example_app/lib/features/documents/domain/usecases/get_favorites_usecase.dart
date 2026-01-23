import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';

@injectable
class GetFavoritesUseCase {
  final DocumentRepository _repository;

  GetFavoritesUseCase(this._repository);

  Future<Either<Failure, List<DocumentInfo>>> call() {
    return _repository.getFavorites();
  }
}
