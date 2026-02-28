/// Animated splash screen that checks the auth session.
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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _logoAnimation;
  late final CurvedAnimation _subtitleAnimation;
  late final CurvedAnimation _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.67, curve: Curves.easeOut),
    );

    _subtitleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.33, 0.83, curve: Curves.easeOut),
    );

    _loadingAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.67, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _loadingAnimation.dispose();
    _subtitleAnimation.dispose();
    _logoAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(AppDurations.splash);

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      debugPrint('Session found: ${session.user.email}');
      context.go('/documents');
    } else {
      debugPrint('No session, redirecting to login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LogoWidget(animation: _logoAnimation),
            const SizedBox(height: AppSpacing.xl),
            _SubtitleWidget(animation: _subtitleAnimation),
            const SizedBox(height: AppSpacing.xxxl),
            _LoadingWidget(animation: _loadingAnimation),
          ],
        ),
      ),
    );
  }
}

class _LogoWidget extends AnimatedWidget {
  const _LogoWidget({required Animation<double> animation})
      : super(listenable: animation);

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final scale = 0.85 + (_progress.value * 0.15);
    return Opacity(
      opacity: _progress.value,
      child: Transform.scale(
        scale: scale,
        child: Image.asset(
          'assets/images/elyanotes_logo.png',
          width: 280,
          height: 280,
          errorBuilder: (_, __, ___) => Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
              boxShadow: AppShadows.lg,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtitleWidget extends AnimatedWidget {
  const _SubtitleWidget({required Animation<double> animation})
      : super(listenable: animation);

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _progress.value,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - _progress.value)),
        child: Text(
          'Notlar\u0131n\u0131 \u00f6zg\u00fcrce yarat',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _LoadingWidget extends AnimatedWidget {
  const _LoadingWidget({required Animation<double> animation})
      : super(listenable: animation);

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _progress.value,
      child: const AppLoadingIndicator(
        size: 32,
        color: AppColors.primary,
      ),
    );
  }
}
