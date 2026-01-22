/// Use case for retrieving the current authenticated user.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';
import 'package:example_app/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, User?>> call() {
    return _repository.getCurrentUser();
  }
}
