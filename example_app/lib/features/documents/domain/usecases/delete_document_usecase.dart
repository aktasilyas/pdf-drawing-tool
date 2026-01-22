import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import '../repositories/document_repository.dart';

@injectable
class DeleteDocumentUseCase {
  final DocumentRepository _repository;

  DeleteDocumentUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteDocument(id);
  }
}
