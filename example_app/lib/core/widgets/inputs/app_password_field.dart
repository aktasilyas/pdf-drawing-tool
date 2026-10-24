/// ElyaNotes Design System - AppPasswordField Component
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

/// ElyaNotes modern şifre field komponenti.
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

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  const AppPasswordField({
    this.controller,
    this.label = 'Şifre',
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
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
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Theme-aware colors
    final fillColor = palette.surfaceElevated;
    final textColor = palette.textPrimary;
    final hintColor = palette.textMuted;
    final labelColor = palette.textMuted;
    final iconColor = _isFocused ? palette.accent : palette.textMuted;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: AppTypography.caption.copyWith(
              color: hasError ? palette.danger : labelColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.textField),
              boxShadow: AppShadows.toolbar(
                brightness,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                obscureText: _obscureText,
                onChanged: widget.onChanged,
                validator: widget.validator,
                textInputAction: widget.textInputAction,
                style: AppTypography.bodyMedium.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle:
                      AppTypography.bodyMedium.copyWith(color: hintColor),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    size: AppIconSize.md,
                    color: hasError ? palette.danger : iconColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _toggleVisibility,
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppIconSize.md,
                      color: palette.textMuted,
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
                        ? BorderSide(color: palette.danger, width: 1.5)
                        : BorderSide.none,
                  ),
                  // Focus: 1.5px primary border
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.textField),
                    borderSide: BorderSide(
                      color: hasError ? palette.danger : palette.accent,
                      width: 1.5,
                    ),
                  ),
                  // Error states
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.textField),
                    borderSide: BorderSide(color: palette.danger, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.textField),
                    borderSide: BorderSide(color: palette.danger, width: 1.5),
                  ),
                  // Disabled
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.textField),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.errorText!,
              style: AppTypography.caption.copyWith(color: palette.danger),
            ),
          ],
        ],
      ),
    );
  }
}
