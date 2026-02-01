/// Splash screen that checks the auth session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash for 2 seconds
    await Future.delayed(AppDurations.splash);

    if (!mounted) return;

    // Check Supabase session
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Session exists → Go to documents
      debugPrint('✅ Session found: ${session.user.email}');
      context.go('/documents');
    } else {
      // No session → Go to login
      debugPrint('🔒 No session, redirecting to login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
                boxShadow: AppShadows.lg,
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: AppIconSize.huge + 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Title
            Text(
              'StarNote',
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.onPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Subtitle
            Text(
              'Notlarını özgürce yarat',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            // Loading Indicator
            const AppLoadingIndicator(
              size: 32,
              color: AppColors.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
