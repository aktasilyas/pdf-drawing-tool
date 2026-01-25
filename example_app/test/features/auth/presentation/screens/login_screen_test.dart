import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  late GoRouter router;
  late _FakeAuthController fakeAuthController;

  setUpAll(() async {
    // Initialize Supabase with fake credentials for testing
    try {
      await supabase.Supabase.initialize(
        url: 'https://fake-test-url.supabase.co',
        anonKey: 'fake-test-key',
      );
    } catch (e) {
      // Already initialized, ignore
    }
  });

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
        authControllerProvider.overrideWith((ref) => fakeAuthController),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  setUp(() {
    fakeAuthController = _FakeAuthController();
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(createTestApp());

    // Find and tap the "Giriş Yap" button
    final loginButton = find.widgetWithText(FilledButton, 'Giriş Yap');
    expect(loginButton, findsOneWidget);
    
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Should show validation error
    expect(find.text('E-posta gerekli'), findsOneWidget);
  });

  testWidgets('shows validation error for invalid email', (tester) async {
    await tester.pumpWidget(createTestApp());

    // Enter invalid email
    await tester.enterText(find.byKey(loginEmailFieldKey), 'invalid-email');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'password123');
    
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('Geçerli bir e-posta girin'), findsOneWidget);
  });

  testWidgets('shows validation error for short password', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.enterText(find.byKey(loginEmailFieldKey), 'test@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), '123');
    
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('Şifre en az 6 karakter olmalıdır'), findsOneWidget);
  });

  testWidgets('calls auth controller on valid login', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.enterText(find.byKey(loginEmailFieldKey), 'test@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'password123');
    
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    expect(fakeAuthController.signInCalled, isTrue);
    expect(fakeAuthController.lastEmail, 'test@example.com');
    expect(fakeAuthController.lastPassword, 'password123');
  });

  testWidgets('navigates to documents on successful login', (tester) async {
    fakeAuthController.shouldSucceed = true;
    
    await tester.pumpWidget(createTestApp());

    await tester.enterText(find.byKey(loginEmailFieldKey), 'test@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'password123');
    
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    // Should navigate to documents
    expect(find.text('Documents'), findsOneWidget);
  });

  testWidgets('shows error snackbar on failed login', (tester) async {
    fakeAuthController.shouldSucceed = false;
    fakeAuthController.errorMessage = 'E-posta veya şifre hatalı';
    
    await tester.pumpWidget(createTestApp());

    await tester.enterText(find.byKey(loginEmailFieldKey), 'test@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'wrongpassword');
    
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    // Should show error snackbar
    expect(find.text('E-posta veya şifre hatalı'), findsOneWidget);
  });

  testWidgets('skip button navigates to documents', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Atla (Geliştirme)'));
    await tester.pumpAndSettle();

    expect(find.text('Documents'), findsOneWidget);
  });

  testWidgets('shows forgot password dialog', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.tap(find.text('Şifremi Unuttum'));
    await tester.pumpAndSettle();

    expect(find.text('Şifre Sıfırlama'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Gönder'), findsOneWidget);
  });
}

/// Fake auth controller for testing
class _FakeAuthController extends AuthController {
  bool signInCalled = false;
  bool shouldSucceed = true;
  String? errorMessage;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    lastEmail = email;
    lastPassword = password;

    if (shouldSucceed) {
      return null; // Success
    } else {
      return errorMessage ?? 'Giriş başarısız';
    }
  }

  @override
  Future<String?> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    return null;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> resetPassword(String email) async {
    return null;
  }

  @override
  Future<String?> signInWithGoogle() async {
    return null;
  }
}
