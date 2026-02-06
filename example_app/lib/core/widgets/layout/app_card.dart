/// StarNote Design System - AppCard Component
///
/// Card komponenti. 3 variant destekler.
///
/// Kullanım:
/// ```dart
/// AppCard(
///   variant: AppCardVariant.elevated,
///   onTap: () => navigate(),
///   child: MyContent(),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Card varyantları.
enum AppCardVariant {
  /// Gölgeli card - Surface arka plan + shadow
  elevated,

  /// Dolu card - SurfaceVariant arka plan
  filled,

  /// Kenarlıklı card - Surface arka plan + border
  outlined,
}

/// StarNote card komponenti.
///
/// 3 farklı variant, tıklanabilir, seçilebilir.
class AppCard extends StatelessWidget {
  /// Card içeriği.
  final Widget child;

  /// Card varyantı.
  final AppCardVariant variant;

  /// Tıklama callback'i.
  final VoidCallback? onTap;

  /// Uzun basma callback'i.
  final VoidCallback? onLongPress;

  /// İç boşluk (null ise varsayılan).
  final EdgeInsets? padding;

  /// Seçili durumu.
  final bool isSelected;

  const AppCard({
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.isSelected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: _buildDecoration(isDark),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDark) {
    switch (variant) {
      case AppCardVariant.elevated:
        return BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: isSelected ? null : AppShadows.sm,
        );

      case AppCardVariant.filled:
        return BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        );

      case AppCardVariant.outlined:
        return BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
            width: isSelected ? 2 : 1,
          ),
        );
    }
  }
}
