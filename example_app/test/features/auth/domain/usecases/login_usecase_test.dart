import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';
import 'package:example_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:example_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAuthRepository repository;
  late LoginUseCase useCase;
  final testUser = User(
    id: 'u1',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: null,
    createdAt: DateTime(2024),
    lastLoginAt: DateTime(2025),
  );

  setUp(() {
    repository = _FakeAuthRepository(loginResult: Right(testUser));
    useCase = LoginUseCase(repository);
  });

  test('should forward credentials to repository', () async {
    final result = await useCase(email: 'foo@example.com', password: 'p4ssw0rd');
    expect(repository.loginCalled, isTrue);
    expect(repository.lastEmail, 'foo@example.com');
    expect(result, Right(testUser));
  });

  test('should propagate repository failure', () async {
    repository = _FakeAuthRepository(loginResult: Left(AuthFailure('iptal')));
    useCase = LoginUseCase(repository);

    final result = await useCase(email: 'foo@example.com', password: 'p4ssw0rd');

    expect(result, Left(AuthFailure('iptal')));
  });
}

class _FakeAuthRepository implements AuthRepository {
  final Either<Failure, User> loginResult;
  bool loginCalled = false;
  String? lastEmail;
  String? lastPassword;

  _FakeAuthRepository({required this.loginResult});

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;
    return loginResult;
  }

  @override
  Future<Either<Failure, User>> loginWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> logout() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Stream<User?> watchAuthState() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset(String email) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>> isEmailRegistered(String email) {
    throw UnimplementedError();
  }
}
