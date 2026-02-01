/// StarNote Design System - AppTextField Component
///
/// Temel text input komponenti.
///
/// Kullanım:
/// ```dart
/// AppTextField(
///   label: 'E-posta',
///   hint: 'ornek@email.com',
///   prefixIcon: Icons.email,
///   onChanged: (value) => print(value),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// StarNote text field komponenti.
///
/// Label, hint, error, prefix icon ve suffix widget destekler.
class AppTextField extends StatelessWidget {
  /// Text controller.
  final TextEditingController? controller;

  /// Input üzerindeki label.
  final String? label;

  /// Placeholder metni.
  final String? hint;

  /// Hata mesajı. Varsa kırmızı border gösterilir.
  final String? errorText;

  /// Yardımcı metin (hata yokken gösterilir).
  final String? helperText;

  /// Sol taraftaki icon.
  final IconData? prefixIcon;

  /// Sağ taraftaki widget (icon, button vb.).
  final Widget? suffix;

  /// Input aktif mi?
  final bool enabled;

  /// Sadece okunabilir mi?
  final bool readOnly;

  /// Şifre modu (metin gizlenir).
  final bool obscureText;

  /// Maksimum satır sayısı.
  final int maxLines;

  /// Klavye tipi.
  final TextInputType? keyboardType;

  /// Klavye action butonu.
  final TextInputAction? textInputAction;

  /// Metin değiştiğinde çağrılır.
  final ValueChanged<String>? onChanged;

  /// Submit edildiğinde çağrılır.
  final ValueChanged<String>? onSubmitted;

  /// Form validasyonu için.
  final FormFieldValidator<String>? validator;

  /// Focus node.
  final FocusNode? focusNode;

  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: hasError ? AppColors.error : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: AppTypography.bodyMedium.copyWith(
            color: enabled
                ? AppColors.textPrimaryLight
                : AppColors.textDisabledLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: AppIconSize.md,
                    color: hasError
                        ? AppColors.error
                        : AppColors.textSecondaryLight,
                  )
                : null,
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: suffix,
                  )
                : null,
            filled: true,
            fillColor: enabled
                ? AppColors.surfaceVariantLight
                : AppColors.surfaceVariantLight.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.textField),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.textField),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.outlineLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.textField),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.textField),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.textField),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.textField),
              borderSide: BorderSide(
                color: AppColors.outlineLight.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helperText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ],
    );
  }
}
