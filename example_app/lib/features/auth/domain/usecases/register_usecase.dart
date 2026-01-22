/// Use case for user registration with email and password.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';
import 'package:example_app/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.register(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
