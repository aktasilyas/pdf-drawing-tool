/// StarNote Design System - AppButton Component
///
/// Ana buton komponenti. 5 variant ve 3 size destekler.
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
  /// Ana aksiyon butonu - Primary renk
  primary,

  /// İkincil aksiyon butonu - Surface renk
  secondary,

  /// Kenarlıklı buton - Transparent arka plan
  outline,

  /// Sadece metin butonu - Minimal stil
  text,

  /// Tehlikeli aksiyon butonu - Error renk
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

/// StarNote ana buton komponenti.
///
/// 5 farklı variant ve 3 farklı boyut destekler.
/// Loading state, icon ve expanded özellikleri mevcut.
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
        child: _buildButton(specs, isDisabled),
      ),
    );
  }

  Widget _buildButton(_ButtonSpecs specs, bool isDisabled) {
    final child = _buildContent(specs);

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
          style: _secondaryStyle(specs),
          child: child,
        );

      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _outlineStyle(specs),
          child: child,
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: _textStyle(specs),
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
          fontWeight: FontWeight.w500,
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

  ButtonStyle _primaryStyle(_ButtonSpecs specs) => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      );

  ButtonStyle _secondaryStyle(_ButtonSpecs specs) => ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceVariantLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      );

  ButtonStyle _outlineStyle(_ButtonSpecs specs) => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        side: const BorderSide(color: AppColors.primary),
      );

  ButtonStyle _textStyle(_ButtonSpecs specs) => TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      );

  ButtonStyle _destructiveStyle(_ButtonSpecs specs) => ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.onError,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
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
