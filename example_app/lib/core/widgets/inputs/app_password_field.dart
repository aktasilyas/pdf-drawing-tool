/// StarNote Design System - AppPasswordField Component
///
/// Modern, şifre girişi için özel input komponenti.
/// Default: border yok, sadece fill color.
/// Focus: 1.5px primary border.
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

import 'package:example_app/core/theme/index.dart';

/// StarNote modern şifre field komponenti.
///
/// Modern minimal tasarım:
/// - Default: filled, border yok
/// - Focus: 1.5px primary border
/// - Min height: 48dp
/// - Show/hide toggle
class AppPasswordField extends StatefulWidget {
  /// Text controller.
  final TextEditingController? controller;

  /// Input üzerindeki label (üstte sabit).
  final String label;

  /// Placeholder metni.
  final String? hint;

  /// Hata mesajı.
  final String? errorText;

  /// Metin değiştiğinde çağrılır.
  final ValueChanged<String>? onChanged;

  /// Form validasyonu için.
  final FormFieldValidator<String>? validator;

  /// Focus node.
  final FocusNode? focusNode;

  /// Enabled state.
  final bool enabled;

  const AppPasswordField({
    this.controller,
    this.label = 'Şifre',
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.enabled = true,
    super.key,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  late FocusNode _focusNode;
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Theme-aware colors
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final iconColor = _isFocused
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: AppTypography.caption.copyWith(
              color: hasError ? AppColors.error : labelColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              obscureText: _obscureText,
              onChanged: widget.onChanged,
              validator: widget.validator,
              style: AppTypography.bodyMedium.copyWith(color: textColor),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  size: AppIconSize.md,
                  color: hasError ? AppColors.error : iconColor,
                ),
                suffixIcon: IconButton(
                  onPressed: _toggleVisibility,
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: AppIconSize.md,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  splashRadius: AppSpacing.lg,
                ),
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 14, // 14dp vertical padding
                ),
                // Default: border yok
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.textField),
                  borderSide: BorderSide.none,
                ),
                // Enabled: border yok (modern minimal)
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.textField),
                  borderSide: hasError
                      ? const BorderSide(color: AppColors.error, width: 1.5)
                      : BorderSide.none,
                ),
                // Focus: 1.5px primary border
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.textField),
                  borderSide: BorderSide(
                    color: hasError ? AppColors.error : AppColors.primary,
                    width: 1.5,
                  ),
                ),
                // Error states
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.textField),
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.textField),
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 1.5),
                ),
                // Disabled
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.textField),
                  borderSide: BorderSide.none,
                ),
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
      ),
    );
  }
}
