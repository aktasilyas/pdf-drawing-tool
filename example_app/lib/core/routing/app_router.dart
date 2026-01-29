/// App router configuration using GoRouter.
/// 
/// Routes are organized by feature:
/// - Auth routes (login, register)
/// - Document routes (list, folder, favorites)
/// - Editor routes
/// - Settings routes
/// - Premium routes
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:example_app/features/auth/presentation/screens/login_screen.dart';
import 'package:example_app/features/auth/presentation/screens/register_screen.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';
import 'package:example_app/features/documents/presentation/screens/template_selection_screen.dart';
import 'package:example_app/features/editor/presentation/screens/editor_screen.dart';
import 'package:example_app/features/settings/settings.dart';

/// Global router configuration
final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  debugLogDiagnostics: true,
  routes: [
    // Auth routes
    GoRoute(
      path: RouteNames.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
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
      builder: (context, state) => const _PlaceholderScreen(title: 'Forgot Password'),
    ),

    // Document routes
    GoRoute(
      path: RouteNames.documents,
      name: 'documents',
      builder: (context, state) => const DocumentsScreen(),
    ),
    GoRoute(
      path: RouteNames.folder,
      name: 'folder',
      builder: (context, state) {
        // TODO: Pass folderId to DocumentsScreen when implemented
        // final folderId = state.pathParameters['folderId']!;
        return const DocumentsScreen();
      },
    ),
    GoRoute(
      path: RouteNames.favorites,
      name: 'favorites',
      builder: (context, state) => const _PlaceholderScreen(title: 'Favorites'),
    ),
    GoRoute(
      path: RouteNames.recent,
      name: 'recent',
      builder: (context, state) => const _PlaceholderScreen(title: 'Recent'),
    ),
    GoRoute(
      path: RouteNames.trash,
      name: 'trash',
      builder: (context, state) => const _PlaceholderScreen(title: 'Trash'),
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

    // Premium routes
    GoRoute(
      path: RouteNames.paywall,
      name: 'paywall',
      builder: (context, state) => const _PlaceholderScreen(title: 'Paywall'),
    ),
    GoRoute(
      path: RouteNames.subscription,
      name: 'subscription',
      builder: (context, state) => const _PlaceholderScreen(title: 'Subscription'),
    ),
  ],
  
  // Error handling
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Sayfa bulunamadı: ${state.uri}'),
    ),
  ),
  
  // Redirect logic for auth
  redirect: (context, state) {
    // TODO: Implement auth redirect logic when auth provider is ready
    return null;
  },
);

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
