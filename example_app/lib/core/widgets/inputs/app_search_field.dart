/// StarNote Design System - AppSearchField Component
///
/// Modern, debounce destekli arama input'u.
/// Default: border yok, sadece fill color.
/// Focus: 1.5px primary border.
///
/// Kullanım:
/// ```dart
/// AppSearchField(
///   hint: 'Doküman ara...',
///   onChanged: (query) => search(query),
///   debounceDuration: Duration(milliseconds: 300),
/// )
/// ```
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// StarNote modern arama field komponenti.
///
/// Modern minimal tasarım:
/// - Default: filled, border yok
/// - Focus: 1.5px primary border
/// - Min height: 48dp
class AppSearchField extends StatefulWidget {
  /// Placeholder metni.
  final String hint;

  /// Debounce sonrası çağrılır.
  final ValueChanged<String>? onChanged;

  /// Clear butonuna tıklandığında çağrılır.
  final VoidCallback? onClear;

  /// Debounce süresi.
  final Duration debounceDuration;

  /// External text value to sync with (e.g. from a provider).
  /// When this changes externally, the text field updates accordingly.
  final String? text;

  const AppSearchField({
    this.hint = 'Ara...',
    this.onChanged,
    this.onClear,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.text,
    super.key,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller with external text without triggering onChanged loop
    if (widget.text != null && widget.text != _controller.text) {
      _controller.removeListener(_onTextChanged);
      _controller.text = widget.text!;
      _hasText = _controller.text.isNotEmpty;
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(_controller.text);
    });
  }

  void _onClear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final iconColor = _isFocused
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: AppTypography.bodyMedium.copyWith(color: textColor),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
          prefixIcon: Icon(
            Icons.search,
            size: AppIconSize.md,
            color: iconColor,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: _onClear,
                  icon: Icon(
                    Icons.close,
                    size: AppIconSize.md,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  splashRadius: AppSpacing.lg,
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
            borderSide: BorderSide.none,
          ),
          // Focus: 1.5px primary border
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.textField),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
