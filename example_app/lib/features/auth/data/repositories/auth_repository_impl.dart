/// Supabase-backed implementation of the auth repository.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';
import 'package:example_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      return Right(user.toEntity());
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message, code: error.code));
    } catch (error) {
      return Left(AuthFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithGoogle() async {
    try {
      final user = await _remoteDataSource.loginWithGoogle();
      return Right(user.toEntity());
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message, code: error.code));
    } catch (error) {
      return Left(AuthFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      return Right(user.toEntity());
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message, code: error.code));
    } catch (error) {
      return Left(AuthFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(null);
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message, code: error.code));
    } catch (error) {
      return Left(AuthFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user?.toEntity());
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message, code: error.code));
    } catch (error) {
      return Left(AuthFailure(error.toString()));
    }
  }

  @override
  Stream<User?> watchAuthState() {
    return _remoteDataSource.watchAuthState().map((user) => user?.toEntity());
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    try {
      await _remoteDataSource.sendPasswordReset(email);
      return const Right(null);
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message, code: error.code));
    } catch (error) {
      return Left(AuthFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailRegistered(String email) async {
    try {
      final isRegistered = await _remoteDataSource.isEmailRegistered(email);
      return Right(isRegistered);
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message, code: error.code));
    } catch (error) {
      return Left(AuthFailure(error.toString()));
    }
  }
}
