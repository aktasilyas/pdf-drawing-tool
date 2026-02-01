/// StarNote Design System - AppSearchField Component
///
/// Debounce destekli arama input'u.
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

/// StarNote arama field komponenti.
///
/// Search icon, clear button ve debounce destekler.
class AppSearchField extends StatefulWidget {
  /// Placeholder metni.
  final String hint;

  /// Debounce sonrası çağrılır.
  final ValueChanged<String>? onChanged;

  /// Clear butonuna tıklandığında çağrılır.
  final VoidCallback? onClear;

  /// Debounce süresi.
  final Duration debounceDuration;

  const AppSearchField({
    this.hint = 'Ara...',
    this.onChanged,
    this.onClear,
    this.debounceDuration = const Duration(milliseconds: 300),
    super.key,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
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
    return TextField(
      controller: _controller,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: AppIconSize.md,
          color: AppColors.textSecondaryLight,
        ),
        suffixIcon: _hasText
            ? IconButton(
                onPressed: _onClear,
                icon: const Icon(
                  Icons.close,
                  size: AppIconSize.md,
                  color: AppColors.textSecondaryLight,
                ),
                splashRadius: AppSpacing.lg,
              )
            : null,
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
          borderSide: const BorderSide(color: AppColors.outlineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
