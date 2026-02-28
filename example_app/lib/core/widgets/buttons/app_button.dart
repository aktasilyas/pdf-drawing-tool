/// ElyaNotes Design System - AppButton Component
///
/// Modern, flat buton komponenti. 5 variant ve 3 size destekler.
/// Rounded, flat, modern tasarım.
///
/// Kullanım:
/// ```dart
/// AppButton(
///   label: 'Kaydet',
///   onPressed: () => save(),
///   variant: AppButtonVariant.primary,
///   size: AppButtonSize.medium,
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Buton varyantları.
enum AppButtonVariant {
  /// Ana aksiyon butonu - Primary renk, flat
  primary,

  /// İkincil aksiyon butonu - SurfaceVariant renk
  secondary,

  /// Kenarlıklı buton - 1px outline, transparent bg
  outline,

  /// Sadece metin butonu - Minimal stil
  text,

  /// Tehlikeli aksiyon butonu - Error renk, beyaz text
  destructive,
}

/// Buton boyutları.
enum AppButtonSize {
  /// Küçük: 36dp yükseklik
  small,

  /// Orta: 44dp yükseklik (varsayılan)
  medium,

  /// Büyük: 52dp yükseklik
  large,
}

/// ElyaNotes modern buton komponenti.
///
/// Modern tasarım kuralları:
/// - Border radius: AppRadius.md (10) — soft rectangle
/// - Elevation: default 0, press 1
/// - Font weight: w600 (Material default w500 değil)
/// - Letter spacing: 0 (Material default 1.25 kaldırıldı)
/// - Subtle ripple effect
class AppButton extends StatelessWidget {
  /// Buton üzerindeki metin.
  final String label;

  /// Butona tıklandığında çağrılacak fonksiyon.
  /// Null ise buton disabled görünür.
  final VoidCallback? onPressed;

  /// Buton varyantı.
  final AppButtonVariant variant;

  /// Buton boyutu.
  final AppButtonSize size;

  /// Sol taraftaki icon.
  final IconData? leadingIcon;

  /// Sağ taraftaki icon.
  final IconData? trailingIcon;

  /// Loading durumu. True ise spinner gösterilir.
  final bool isLoading;

  /// True ise buton tüm genişliği kaplar.
  final bool isExpanded;

  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final specs = _getSpecs();

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: SizedBox(
        height: specs.height,
        width: isExpanded ? double.infinity : null,
        child: _buildButton(context, specs, isDisabled),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, _ButtonSpecs specs, bool isDisabled) {
    final child = _buildContent(specs);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _primaryStyle(specs),
          child: child,
        );

      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _secondaryStyle(specs, isDark),
          child: child,
        );

      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _outlineStyle(specs, isDark),
          child: child,
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: _textStyle(specs, isDark),
          child: child,
        );

      case AppButtonVariant.destructive:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _destructiveStyle(specs),
          child: child,
        );
    }
  }

  Widget _buildContent(_ButtonSpecs specs) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _getLoadingColor(),
        ),
      );
    }

    final children = <Widget>[];

    if (leadingIcon != null) {
      children.add(Icon(leadingIcon, size: specs.iconSize));
      children.add(const SizedBox(width: AppSpacing.sm));
    }

    children.add(
      Text(
        label,
        style: TextStyle(
          fontSize: specs.fontSize,
          fontWeight: FontWeight.w600, // w500 → w600 (daha modern)
          letterSpacing: 0, // Material default 1.25 kaldırıldı
        ),
      ),
    );

    if (trailingIcon != null) {
      children.add(const SizedBox(width: AppSpacing.sm));
      children.add(Icon(trailingIcon, size: specs.iconSize));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Color _getLoadingColor() {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return AppColors.onPrimary;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return AppColors.primary;
    }
  }

  _ButtonSpecs _getSpecs() {
    switch (size) {
      case AppButtonSize.small:
        return const _ButtonSpecs(
          height: 36,
          horizontalPadding: AppSpacing.md,
          fontSize: 13,
          iconSize: AppIconSize.sm,
        );
      case AppButtonSize.medium:
        return const _ButtonSpecs(
          height: 44,
          horizontalPadding: AppSpacing.lg,
          fontSize: 14,
          iconSize: AppIconSize.md,
        );
      case AppButtonSize.large:
        return const _ButtonSpecs(
          height: 52,
          horizontalPadding: AppSpacing.xl,
          fontSize: 15,
          iconSize: AppIconSize.md,
        );
    }
  }

  /// Primary: Flat renk, shadow yok (default), press'te çok hafif elevation
  ButtonStyle _primaryStyle(_ButtonSpecs specs) => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        splashFactory: InkRipple.splashFactory,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 1;
          return 0;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primaryDark;
          }
          return AppColors.primary;
        }),
      );

  /// Secondary: surfaceVariant bg, textPrimary renk
  ButtonStyle _secondaryStyle(_ButtonSpecs specs, bool isDark) =>
      ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        splashFactory: InkRipple.splashFactory,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 1;
          return 0;
        }),
      );

  /// Outline: 1px border, transparent bg, hover/press'te hafif fill
  ButtonStyle _outlineStyle(_ButtonSpecs specs, bool isDark) {
    final outlineColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;
    final hoverFill =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return OutlinedButton.styleFrom(
      foregroundColor: isDark ? AppColors.accent : AppColors.primary,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      side: BorderSide(color: outlineColor),
      splashFactory: InkRipple.splashFactory,
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered)) {
          return hoverFill;
        }
        return Colors.transparent;
      }),
    );
  }

  /// Text: arka plan yok, border yok, sadece text + ripple
  ButtonStyle _textStyle(_ButtonSpecs specs, bool isDark) =>
      TextButton.styleFrom(
        foregroundColor: isDark ? AppColors.accent : AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        splashFactory: InkRipple.splashFactory,
      );

  /// Destructive: flat error renk, beyaz text
  ButtonStyle _destructiveStyle(_ButtonSpecs specs) => ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.onError,
        elevation: 0,
        shadowColor: AppColors.error.withValues(alpha: 0.3),
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        splashFactory: InkRipple.splashFactory,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 1;
          return 0;
        }),
      );
}

/// Buton boyut spesifikasyonları.
class _ButtonSpecs {
  final double height;
  final double horizontalPadding;
  final double fontSize;
  final double iconSize;

  const _ButtonSpecs({
    required this.height,
    required this.horizontalPadding,
    required this.fontSize,
    required this.iconSize,
  });
}
