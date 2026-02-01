/// StarNote Design System - AppPasswordField Component
///
/// Şifre girişi için özel input komponenti.
///
/// Kullanım:
/// ```dart
/// AppPasswordField(
///   label: 'Şifre',
///   hint: 'Şifrenizi girin',
///   onChanged: (value) => print(value),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import '../../theme/tokens/index.dart';

/// StarNote şifre field komponenti.
///
/// Show/hide toggle ve validation destekler.
class AppPasswordField extends StatefulWidget {
  /// Text controller.
  final TextEditingController? controller;

  /// Input üzerindeki label.
  final String label;

  /// Placeholder metni.
  final String? hint;

  /// Hata mesajı.
  final String? errorText;

  /// Metin değiştiğinde çağrılır.
  final ValueChanged<String>? onChanged;

  /// Form validasyonu için.
  final FormFieldValidator<String>? validator;

  const AppPasswordField({
    this.controller,
    this.label = 'Şifre',
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    super.key,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: hasError ? AppColors.error : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              size: AppIconSize.md,
              color: hasError ? AppColors.error : AppColors.textSecondaryLight,
            ),
            suffixIcon: IconButton(
              onPressed: _toggleVisibility,
              icon: Icon(
                _obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppIconSize.md,
                color: AppColors.textSecondaryLight,
              ),
              splashRadius: AppSpacing.lg,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariantLight,
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
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
