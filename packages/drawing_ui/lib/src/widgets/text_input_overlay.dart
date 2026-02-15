import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// Text input overlay for editing text elements
class TextInputOverlay extends ConsumerStatefulWidget {
  final TextElement textElement;
  final double zoom;
  final Offset canvasOffset;
  final ValueChanged<TextElement> onTextChanged;
  final VoidCallback onEditingComplete;
  final VoidCallback onCancel;

  const TextInputOverlay({
    super.key,
    required this.textElement,
    required this.zoom,
    required this.canvasOffset,
    required this.onTextChanged,
    required this.onEditingComplete,
    required this.onCancel,
  });

  @override
  ConsumerState<TextInputOverlay> createState() => _TextInputOverlayState();
}

class _TextInputOverlayState extends ConsumerState<TextInputOverlay> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.textElement.text);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);

    // Auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Listen to text changes
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // When focus is lost (keyboard dismissed, tap outside, etc.) save the text
    if (!_focusNode.hasFocus) {
      if (_controller.text.trim().isNotEmpty) {
        widget.onEditingComplete();
      } else {
        widget.onCancel();
      }
    }
  }

  void _onTextChanged() {
    final updatedText = widget.textElement.copyWith(text: _controller.text);
    widget.onTextChanged(updatedText);
  }

  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      widget.onEditingComplete();
    } else {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate position based on canvas transform
    final screenX = widget.textElement.x * widget.zoom + widget.canvasOffset.dx;
    final screenY = widget.textElement.y * widget.zoom + widget.canvasOffset.dy;

    // Scaled font size
    final scaledFontSize = widget.textElement.fontSize * widget.zoom;

    return Positioned(
      left: screenX,
      top: screenY,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            minWidth: 100 * widget.zoom,
            maxWidth: MediaQuery.of(context).size.width - screenX - 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border.all(color: const Color(0xFF2196F3), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: IntrinsicWidth(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                fontSize: scaledFontSize.clamp(12.0, 72.0),
                fontFamily: widget.textElement.fontFamily,
                fontWeight: widget.textElement.isBold
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontStyle: widget.textElement.isItalic
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: Color(widget.textElement.color),
                decoration: widget.textElement.isUnderline
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
              textAlign: _getTextAlign(),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: _onSubmitted,
            ),
          ),
        ),
      ),
    );
  }

  TextAlign _getTextAlign() {
    switch (widget.textElement.alignment) {
      case TextAlignment.left:
        return TextAlign.left;
      case TextAlignment.center:
        return TextAlign.center;
      case TextAlignment.right:
        return TextAlign.right;
    }
  }
}
