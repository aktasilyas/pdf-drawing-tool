/// StarNote Design System - AppLoading Components
///
/// Loading göstergeleri.
///
/// Kullanım:
/// ```dart
/// // Basit indicator
/// AppLoadingIndicator()
///
/// // Overlay ile
/// AppLoadingOverlay(
///   isLoading: isProcessing,
///   message: 'Yükleniyor...',
///   child: MyContent(),
/// )
///
/// // Skeleton loader
/// AppSkeletonLoader(width: 200, height: 20)
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Basit loading indicator.
///
/// CircularProgressIndicator wrapper'ı.
class AppLoadingIndicator extends StatelessWidget {
  /// Indicator boyutu.
  final double size;

  /// Indicator rengi (null ise theme'den alınır).
  final Color? color;

  const AppLoadingIndicator({
    this.size = 24,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size / 12,
        color: color ?? AppColors.primary,
      ),
    );
  }
}

/// Loading overlay komponenti.
///
/// Child widget'ın üzerine yarı saydam overlay ve loading indicator ekler.
class AppLoadingOverlay extends StatelessWidget {
  /// İçerik widget'ı.
  final Widget child;

  /// Loading gösterilsin mi?
  final bool isLoading;

  /// Loading mesajı (opsiyonel).
  final String? message;

  const AppLoadingOverlay({
    required this.child,
    required this.isLoading,
    this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: AppColors.backgroundLight.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLoadingIndicator(size: 40),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        message!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Skeleton loader komponenti.
///
/// İçerik yüklenirken placeholder olarak kullanılır.
class AppSkeletonLoader extends StatefulWidget {
  /// Skeleton genişliği.
  final double width;

  /// Skeleton yüksekliği.
  final double height;

  /// Köşe radius'u.
  final double borderRadius;

  const AppSkeletonLoader({
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
    super.key,
  });

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.slower * 3, // 1.5 seconds
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.surfaceVariantLight,
                AppColors.outlineVariantLight,
                AppColors.surfaceVariantLight,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}
