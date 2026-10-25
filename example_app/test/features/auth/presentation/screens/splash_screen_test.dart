import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/auth/presentation/screens/splash_screen.dart';

class _MockSession extends Mock implements Session {}

class _MockUser extends Mock implements User {}

void main() {
  Future<void> pumpSplash(
    WidgetTester tester, {
    required FeatureFlags flags,
    required Session? Function() session,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/documents', builder: (_, __) => const Text('docs')),
        GoRoute(path: '/login', builder: (_, __) => const Text('login')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWithValue(flags),
          sessionProvider.overrideWith((ref) => session()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump(AppDurations.splash + const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('cloud off: goes to /documents without reading the session',
      (tester) async {
    await pumpSplash(
      tester,
      flags: FeatureFlags.allOff,
      session: () => throw StateError('Supabase must not be touched'),
    );
    expect(find.text('docs'), findsOneWidget);
  });

  testWidgets('cloud on, no session: goes to /login', (tester) async {
    await pumpSplash(
      tester,
      flags: const FeatureFlags(cloudSync: true),
      session: () => null,
    );
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('cloud on, session present: goes to /documents', (tester) async {
    final session = _MockSession();
    final user = _MockUser();
    when(() => session.user).thenReturn(user);
    when(() => user.email).thenReturn('a@b.c');
    await pumpSplash(
      tester,
      flags: const FeatureFlags(cloudSync: true),
      session: () => session,
    );
    expect(find.text('docs'), findsOneWidget);
  });
}
