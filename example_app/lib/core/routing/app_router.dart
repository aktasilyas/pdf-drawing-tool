/// App router configuration using GoRouter.
///
/// Routes are organized by feature:
/// - Auth routes (login, register)
/// - Document routes (library; folders, favorites, recents, trash are in-screen sections)
/// - Editor routes
/// - Settings routes
/// - Premium routes
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:example_app/features/auth/presentation/screens/login_screen.dart';
import 'package:example_app/features/auth/presentation/screens/register_screen.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';
import 'package:example_app/features/documents/presentation/screens/manage_folders_screen.dart';
import 'package:example_app/features/documents/presentation/screens/template_selection_screen.dart';
import 'package:example_app/features/editor/presentation/screens/editor_screen.dart';
import 'package:example_app/features/premium/presentation/screens/paywall_placeholder_screen.dart';
import 'package:example_app/features/settings/settings.dart';

/// Auth routes that only exist when Supabase is initialized (cloud sync or AI).
const _authPaths = {
  RouteNames.login,
  RouteNames.register,
  RouteNames.forgotPassword,
};

/// Premium routes that only exist when premium is on.
const _premiumPaths = {RouteNames.paywall, RouteNames.subscription};

/// Key of the root Navigator. Lets app-level widgets (mounted above the
/// routes) reach the Navigator for dialogs and routing.
final appNavigatorKeyProvider =
    Provider<GlobalKey<NavigatorState>>((ref) => GlobalKey<NavigatorState>());

/// Router for the app, reading the router from the flags-aware provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter(
    ref.watch(featureFlagsProvider),
    navigatorKey: ref.watch(appNavigatorKeyProvider),
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Builds the router for the given [flags].
///
/// Auth routes exist only with `cloudSync`, paywall/subscription routes only
/// with `premium`. With cloud off, auth paths redirect to the documents list.
GoRouter buildAppRouter(
  FeatureFlags flags, {
  String initialLocation = RouteNames.splash,
  bool debugLog = false,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: debugLog,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      if (flags.needsSupabase) ...[
        GoRoute(
          path: RouteNames.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RouteNames.register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: RouteNames.forgotPassword,
          name: 'forgotPassword',
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Forgot Password'),
        ),
      ],
      // Document routes
      GoRoute(
        path: RouteNames.documents,
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/manage-folders',
        name: 'manageFolders',
        builder: (context, state) => const ManageFoldersScreen(),
      ),

      // Editor routes
      GoRoute(
        path: RouteNames.editor,
        name: 'editor',
        builder: (context, state) {
          final documentId = state.pathParameters['documentId']!;
          return EditorScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: RouteNames.newDocument,
        name: 'newDocument',
        builder: (context, state) {
          // Create new document - pass empty/new document id
          return const EditorScreen(documentId: 'new');
        },
      ),
      GoRoute(
        path: RouteNames.templateSelection,
        name: 'templateSelection',
        builder: (context, state) => const TemplateSelectionScreen(),
      ),

      // Settings routes
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
      ),

      if (flags.premium) ...[
        GoRoute(
          path: RouteNames.paywall,
          name: 'paywall',
          builder: (context, state) => const Scaffold(
            body: SafeArea(child: PaywallPlaceholderScreen()),
          ),
        ),
        GoRoute(
          path: RouteNames.subscription,
          name: 'subscription',
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Subscription'),
        ),
      ],
    ],

    // Error handling
    errorBuilder: libraryFallbackBuilder,

    redirect: (context, state) {
      if (!flags.needsSupabase && _authPaths.contains(state.uri.path)) {
        return RouteNames.documents;
      }
      if (!flags.premium && _premiumPaths.contains(state.uri.path)) {
        return RouteNames.documents;
      }
      return null;
    },
  );
}

/// Unknown paths (stale deep links) land on the library, not an error page.
Widget libraryFallbackBuilder(BuildContext context, GoRouterState state) =>
    const _RedirectToLibrary();

class _RedirectToLibrary extends StatefulWidget {
  const _RedirectToLibrary();

  @override
  State<_RedirectToLibrary> createState() => _RedirectToLibraryState();
}

class _RedirectToLibraryState extends State<_RedirectToLibrary> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(RouteNames.documents);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

/// Temporary placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu ekran henüz yapım aşamasında',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
