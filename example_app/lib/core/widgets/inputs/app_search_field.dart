/// ElyaNotes Design System - AppSearchField Component
///
/// Modern, debounce destekli arama input'u.
/// Default: 1dp hairline border + fill color.
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

import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// ElyaNotes modern arama field komponenti.
///
/// Modern minimal tasarım:
/// - Default: filled, 1dp border
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
    // Only on an external change: syncing on every rebuild would overwrite
    // what the user is typing during the debounce window.
    if (widget.text != null &&
        widget.text != oldWidget.text &&
        widget.text != _controller.text) {
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
    final palette = context.palette;

    // Theme-aware colors
    final fillColor = palette.surface;
    final textColor = palette.textPrimary;
    final hintColor = palette.textMuted;
    final iconColor = _isFocused ? palette.accent : palette.textMuted;

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
            ElyanotesIcons.librarySearch,
            size: AppIconSize.md,
            color: iconColor,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: _onClear,
                  icon: Icon(
                    ElyanotesIcons.libraryClose,
                    size: AppIconSize.md,
                    color: palette.textMuted,
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
          // Default and enabled: 1dp hairline (surface alone is invisible
          // on background).
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.textField),
            borderSide: BorderSide(color: palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.textField),
            borderSide: BorderSide(color: palette.border),
          ),
          // Focus: 1.5px primary border
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.textField),
            borderSide: BorderSide(color: palette.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}
