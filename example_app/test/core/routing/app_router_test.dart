import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/routing/app_router.dart';
import 'package:example_app/core/routing/route_names.dart';

Set<String> _paths(GoRouter router) =>
    router.configuration.routes.whereType<GoRoute>().map((r) => r.path).toSet();

void main() {
  group('buildAppRouter route table', () {
    test('all flags off: no auth and no premium routes', () {
      final paths = _paths(buildAppRouter(FeatureFlags.allOff));
      expect(paths, contains(RouteNames.splash));
      expect(paths, contains(RouteNames.documents));
      expect(paths, contains(RouteNames.settings));
      expect(paths, isNot(contains(RouteNames.login)));
      expect(paths, isNot(contains(RouteNames.register)));
      expect(paths, isNot(contains(RouteNames.forgotPassword)));
      expect(paths, isNot(contains(RouteNames.paywall)));
      expect(paths, isNot(contains(RouteNames.subscription)));
    });

    test('cloudSync only: auth routes, no premium routes', () {
      final paths = _paths(
        buildAppRouter(const FeatureFlags(cloudSync: true)),
      );
      expect(paths, containsAll([RouteNames.login, RouteNames.register]));
      expect(paths, contains(RouteNames.forgotPassword));
      expect(paths, isNot(contains(RouteNames.paywall)));
    });

    test('premium only: premium routes, no auth routes', () {
      final paths = _paths(buildAppRouter(const FeatureFlags(premium: true)));
      expect(paths, containsAll([RouteNames.paywall, RouteNames.subscription]));
      expect(paths, isNot(contains(RouteNames.login)));
    });

    test('all flags on: everything registered', () {
      final paths = _paths(buildAppRouter(FeatureFlags.allOn));
      expect(
        paths,
        containsAll([
          RouteNames.login,
          RouteNames.register,
          RouteNames.paywall,
          RouteNames.subscription,
        ]),
      );
    });
  });

  group('appRouterProvider', () {
    test('builds the router from featureFlagsProvider', () {
      final off = ProviderContainer(
        overrides: [
          featureFlagsProvider.overrideWithValue(FeatureFlags.allOff)
        ],
      );
      final on = ProviderContainer(
        overrides: [featureFlagsProvider.overrideWithValue(FeatureFlags.allOn)],
      );
      addTearDown(off.dispose);
      addTearDown(on.dispose);

      expect(_paths(off.read(appRouterProvider)),
          isNot(contains(RouteNames.login)));
      expect(_paths(on.read(appRouterProvider)), contains(RouteNames.login));
    });
  });

  group('auth redirect', () {
    Future<GoRouter> pumpAt(
      WidgetTester tester,
      FeatureFlags flags,
      String location,
    ) async {
      // Replace heavy screens: only the redirect decision is under test.
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: RouteNames.documents,
            builder: (_, __) => const Text('documents-screen'),
          ),
          GoRoute(
            path: RouteNames.login,
            builder: (_, __) => const Text('login-screen'),
          ),
        ],
        redirect: buildAppRouter(flags).configuration.topRedirect,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      return router;
    }

    for (final path in [
      RouteNames.login,
      RouteNames.register,
      RouteNames.forgotPassword,
    ]) {
      testWidgets('cloud off: $path redirects to /documents', (tester) async {
        await pumpAt(tester, FeatureFlags.allOff, path);
        expect(find.text('documents-screen'), findsOneWidget);
      });
    }

    testWidgets('cloud on: /login is not redirected', (tester) async {
      await pumpAt(tester, FeatureFlags.allOn, RouteNames.login);
      expect(find.text('login-screen'), findsOneWidget);
    });
  });

  group('unknown paths', () {
    for (final path in ['/trash', '/does-not-exist']) {
      testWidgets('$path lands on the library', (tester) async {
        final router = GoRouter(
          initialLocation: path,
          routes: [
            GoRoute(
              path: RouteNames.documents,
              builder: (_, __) => const Text('documents-screen'),
            ),
          ],
          errorBuilder: libraryFallbackBuilder,
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(find.text('documents-screen'), findsOneWidget);
      });
    }
  });
}
