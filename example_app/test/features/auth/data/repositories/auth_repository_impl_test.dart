import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/data/models/user_model.dart';
import 'package:example_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:example_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRemoteDataSource remote;
  late AuthRepositoryImpl repository;

  final userModel = UserModel(
    id: 'user-id',
    email: 'test@example.com',
    displayName: 'Test',
    photoUrl: null,
    createdAt: DateTime(2024),
    lastLoginAt: DateTime(2025),
  );

  setUp(() {
    remote = _FakeRemoteDataSource();
    repository = AuthRepositoryImpl(remote);
  });

  test('login returns user when datasource succeeds', () async {
    remote.loginResult = userModel;
    final result = await repository.login(
      email: 'test@example.com',
      password: 'secret',
    );

    expect(result, Right<Failure, User>(userModel.toEntity()));
    expect(remote.loginCalled, isTrue);
  });

  test('login maps datasource AuthException to AuthFailure', () async {
    remote.shouldThrowOnLogin = true;
    final result = await repository.login(
      email: 'test@example.com',
      password: 'secret',
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<AuthFailure>()),
      (_) => fail('Should not return success'),
    );
  });

  test('isEmailRegistered propagates bool result', () async {
    remote.emailRegisteredResult = true;
    final result = await repository.isEmailRegistered('test@example.com');
    expect(result, const Right(true));
  });
}

class _FakeRemoteDataSource implements AuthRemoteDataSource {
  UserModel? loginResult;
  bool loginCalled = false;
  bool shouldThrowOnLogin = false;
  bool emailRegisteredResult = false;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (shouldThrowOnLogin) {
      throw const AuthException('failed', code: 'error');
    }
    loginCalled = true;
    return loginResult!;
  }

  @override
  Future<UserModel> loginWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Stream<UserModel?> watchAuthState() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordReset(String email) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    return emailRegisteredResult;
  }
}
