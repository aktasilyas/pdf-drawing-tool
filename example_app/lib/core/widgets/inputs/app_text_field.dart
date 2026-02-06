/// StarNote Design System - AppTextField Component
///
/// Modern, filled text input komponenti.
/// Default: border yok, sadece fill color.
/// Focus: 1.5px primary border.
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

/// StarNote modern text field komponenti.
///
/// Modern minimal tasarım:
/// - Default: filled, border yok
/// - Focus: 1.5px primary border
/// - Error: 1.5px error border
/// - Min height: 48dp
class AppTextField extends StatefulWidget {
  /// Text controller.
  final TextEditingController? controller;

  /// Input üzerindeki label (üstte sabit).
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
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
    final disabledTextColor =
        isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight;
    final iconColor = _isFocused
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppTypography.caption.copyWith(
                color: hasError ? AppColors.error : labelColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              obscureText: widget.obscureText,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              validator: widget.validator,
              style: AppTypography.bodyMedium.copyWith(
                color: widget.enabled ? textColor : disabledTextColor,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        size: AppIconSize.md,
                        color: hasError ? AppColors.error : iconColor,
                      )
                    : null,
                suffixIcon: widget.suffix != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: widget.suffix,
                      )
                    : null,
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
          ] else if (widget.helperText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.helperText!,
              style: AppTypography.caption.copyWith(color: hintColor),
            ),
          ],
        ],
      ),
    );
  }
}
