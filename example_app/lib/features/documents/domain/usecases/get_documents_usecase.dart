import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import '../entities/document_info.dart';
import '../repositories/document_repository.dart';

@injectable
class GetDocumentsUseCase {
  final DocumentRepository _repository;

  GetDocumentsUseCase(this._repository);

  Future<Either<Failure, List<DocumentInfo>>> call({String? folderId}) {
    return _repository.getDocuments(folderId: folderId);
  }
}
