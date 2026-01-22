import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';
import 'package:example_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:example_app/features/auth/presentation/constants/auth_strings.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;
  late _FakeAuthRepository fakeRepository;

  Widget createTestApp() {
    router = GoRouter(
      initialLocation: RouteNames.login,
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RouteNames.documents,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Documents')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  final testUser = User(
    id: 'u1',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: null,
    createdAt: DateTime(2023),
    lastLoginAt: DateTime(2024),
  );

  setUp(() {
    fakeRepository = _FakeAuthRepository(testUser);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.tap(find.widgetWithText(FilledButton, AuthStrings.signInButton));
    await tester.pumpAndSettle();

    expect(find.text('E-posta adresi gerekli'), findsOneWidget);
  });

  testWidgets('navigates to documents after successful login', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.enterText(find.byKey(loginEmailFieldKey), testUser.email);
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, AuthStrings.signInButton));
    await tester.pumpAndSettle();

    expect(fakeRepository.loginCalled, isTrue);
    expect(find.text('Documents'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final User successUser;
  bool loginCalled = false;

  _FakeAuthRepository(this.successUser);

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    loginCalled = true;
    return Right(successUser);
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
