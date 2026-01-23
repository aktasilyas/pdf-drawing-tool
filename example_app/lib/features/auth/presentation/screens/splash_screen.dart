/// Splash screen that checks the auth session.
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    // Small delay to show splash screen
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted || _hasRedirected) return;

    try {
      // Try to check auth state
      final authState = ref.read(authStateProvider);
      authState.whenOrNull(
        data: (user) => _redirect(user),
        error: (_, __) => _redirectToDocuments(), // On error, go to documents for testing
        loading: () {
          // Listen for auth state changes
          ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
            next.whenOrNull(
              data: (user) => _redirect(user),
              error: (_, __) => _redirectToDocuments(),
            );
          });
        },
      );
      
      // If still in loading state after 2 seconds, redirect to documents
      Future.delayed(const Duration(seconds: 2), () {
        if (!_hasRedirected && mounted) {
          _redirectToDocuments();
        }
      });
    } catch (e) {
      // Supabase not initialized or other error - go to documents for testing
      debugPrint('Auth check failed: $e');
      _redirectToDocuments();
    }
  }

  void _redirect(User? user) {
    if (_hasRedirected || !mounted) return;
    _hasRedirected = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(user == null ? RouteNames.login : RouteNames.documents);
    });
  }

  void _redirectToDocuments() {
    if (_hasRedirected || !mounted) return;
    _hasRedirected = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Skip login for testing - go directly to documents
      context.go(RouteNames.documents);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.edit_note,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'StarNote',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Çizim ve Not Uygulaması',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
