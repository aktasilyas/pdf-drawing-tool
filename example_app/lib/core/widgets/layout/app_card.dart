/// ElyaNotes Design System - AppCard Component
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

/// ElyaNotes card komponenti.
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
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: _buildDecoration(palette, brightness),
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

  BoxDecoration _buildDecoration(AppPalette palette, Brightness brightness) {
    switch (variant) {
      case AppCardVariant.elevated:
        return BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border:
              isSelected ? Border.all(color: palette.accent, width: 2) : null,
          boxShadow: isSelected ? null : AppShadows.cardResting(brightness),
        );

      case AppCardVariant.filled:
        return BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border:
              isSelected ? Border.all(color: palette.accent, width: 2) : null,
        );

      case AppCardVariant.outlined:
        return BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 2 : 1,
          ),
        );
    }
  }
}
