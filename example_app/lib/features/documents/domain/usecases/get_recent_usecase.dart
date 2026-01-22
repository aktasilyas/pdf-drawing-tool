import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import '../entities/document_info.dart';
import '../repositories/document_repository.dart';

@injectable
class GetRecentUseCase {
  final DocumentRepository _repository;

  GetRecentUseCase(this._repository);

  Future<Either<Failure, List<DocumentInfo>>> call({int limit = 10}) {
    return _repository.getRecent(limit: limit);
  }
}
