/// StarNote Design System - AppIconButton Component
///
/// Icon-only buton komponenti. 4 variant ve 3 size destekler.
///
/// Kullanım:
/// ```dart
/// AppIconButton(
///   icon: Icons.add,
///   onPressed: () => add(),
///   tooltip: 'Ekle',
///   variant: AppIconButtonVariant.filled,
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Icon buton varyantları.
enum AppIconButtonVariant {
  /// Dolu arka plan - Primary renk
  filled,

  /// Tonlu arka plan - Primary light renk
  tonal,

  /// Kenarlıklı - Transparent arka plan
  outline,

  /// Hayalet - Sadece icon
  ghost,
}

/// Icon buton boyutları.
enum AppIconButtonSize {
  /// Küçük: 40dp (48dp touch target)
  small,

  /// Orta: 44dp (varsayılan)
  medium,

  /// Büyük: 52dp
  large,
}

/// StarNote icon buton komponenti.
///
/// 4 farklı variant ve 3 farklı boyut destekler.
/// Tooltip accessibility için önemlidir.
class AppIconButton extends StatelessWidget {
  /// Gösterilecek icon.
  final IconData icon;

  /// Butona tıklandığında çağrılacak fonksiyon.
  /// Null ise buton disabled görünür.
  final VoidCallback? onPressed;

  /// Accessibility için tooltip metni.
  final String? tooltip;

  /// Buton varyantı.
  final AppIconButtonVariant variant;

  /// Buton boyutu.
  final AppIconButtonSize size;

  /// Seçili durumu (toggle butonlar için).
  final bool isSelected;

  const AppIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.filled,
    this.size = AppIconButtonSize.medium,
    this.isSelected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final specs = _getSpecs();

    Widget button = Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: SizedBox(
        width: specs.touchTarget,
        height: specs.touchTarget,
        child: Center(
          child: _buildButton(specs, isDisabled),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton(_IconButtonSpecs specs, bool isDisabled) {
    final iconWidget = Icon(icon, size: specs.iconSize);

    switch (variant) {
      case AppIconButtonVariant.filled:
        return _FilledIconButton(
          onPressed: isDisabled ? null : onPressed,
          size: specs.buttonSize,
          isSelected: isSelected,
          child: iconWidget,
        );

      case AppIconButtonVariant.tonal:
        return _TonalIconButton(
          onPressed: isDisabled ? null : onPressed,
          size: specs.buttonSize,
          isSelected: isSelected,
          child: iconWidget,
        );

      case AppIconButtonVariant.outline:
        return _OutlineIconButton(
          onPressed: isDisabled ? null : onPressed,
          size: specs.buttonSize,
          isSelected: isSelected,
          child: iconWidget,
        );

      case AppIconButtonVariant.ghost:
        return _GhostIconButton(
          onPressed: isDisabled ? null : onPressed,
          size: specs.buttonSize,
          isSelected: isSelected,
          child: iconWidget,
        );
    }
  }

  _IconButtonSpecs _getSpecs() {
    switch (size) {
      case AppIconButtonSize.small:
        return const _IconButtonSpecs(
          buttonSize: 40,
          touchTarget: AppSpacing.minTouchTarget,
          iconSize: AppIconSize.md,
        );
      case AppIconButtonSize.medium:
        return const _IconButtonSpecs(
          buttonSize: 44,
          touchTarget: AppSpacing.minTouchTarget,
          iconSize: AppIconSize.lg,
        );
      case AppIconButtonSize.large:
        return const _IconButtonSpecs(
          buttonSize: 52,
          touchTarget: 52,
          iconSize: AppIconSize.lg,
        );
    }
  }
}

/// Icon buton boyut spesifikasyonları.
class _IconButtonSpecs {
  final double buttonSize;
  final double touchTarget;
  final double iconSize;

  const _IconButtonSpecs({
    required this.buttonSize,
    required this.touchTarget,
    required this.iconSize,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// VARIANT WIDGETS
// ══════════════════════════════════════════════════════════════════════════

class _FilledIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;
  final Widget child;

  const _FilledIconButton({
    required this.onPressed,
    required this.size,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryDark : AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: SizedBox(
          width: size,
          height: size,
          child: IconTheme(
            data: const IconThemeData(color: AppColors.onPrimary),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _TonalIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;
  final Widget child;

  const _TonalIconButton({
    required this.onPressed,
    required this.size,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected ? AppColors.primaryLight : AppColors.surfaceVariantLight,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: SizedBox(
          width: size,
          height: size,
          child: IconTheme(
            data: IconThemeData(
              color: isSelected ? AppColors.onPrimary : AppColors.primary,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;
  final Widget child;

  const _OutlineIconButton({
    required this.onPressed,
    required this.size,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: AppColors.primary,
              width: isSelected ? 0 : 1,
            ),
          ),
          child: IconTheme(
            data: IconThemeData(
              color: isSelected ? AppColors.onPrimary : AppColors.primary,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;
  final Widget child;

  const _GhostIconButton({
    required this.onPressed,
    required this.size,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.surfaceVariantLight : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: SizedBox(
          width: size,
          height: size,
          child: IconTheme(
            data: IconThemeData(
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
