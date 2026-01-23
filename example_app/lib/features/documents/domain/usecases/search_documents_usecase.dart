import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';

@injectable
class SearchDocumentsUseCase {
  final DocumentRepository _repository;

  SearchDocumentsUseCase(this._repository);

  Future<Either<Failure, List<DocumentInfo>>> call(String query) {
    if (query.trim().isEmpty) {
      return Future.value(const Right([]));
    }
    return _repository.search(query);
  }
}
