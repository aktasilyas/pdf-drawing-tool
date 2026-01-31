/// Repository contract for auth operations.
library;

import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> loginWithGoogle();

  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User?>> getCurrentUser();

  Stream<User?> watchAuthState();

  Future<Either<Failure, void>> sendPasswordReset(String email);

  Future<Either<Failure, bool>> isEmailRegistered(String email);
}
