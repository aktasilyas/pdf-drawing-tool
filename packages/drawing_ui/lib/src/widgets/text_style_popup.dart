import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'unified_color_picker.dart';

/// Popup for editing text style (color, bold, italic, underline)
class TextStylePopup extends StatefulWidget {
  final TextElement textElement;
  final double zoom;
  final Offset canvasOffset;
  final ValueChanged<TextElement> onStyleChanged;
  final VoidCallback onClose;

  /// When true, only shows size slider (for emoji/sticker editing).
  final bool stickerMode;

  const TextStylePopup({
    super.key,
    required this.textElement,
    required this.zoom,
    required this.canvasOffset,
    required this.onStyleChanged,
    required this.onClose,
    this.stickerMode = false,
  });

  @override
  State<TextStylePopup> createState() => _TextStylePopupState();
}

class _TextStylePopupState extends State<TextStylePopup> {
  late Color _selectedColor;
  late bool _isBold;
  late bool _isItalic;
  late bool _isUnderline;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _selectedColor = Color(widget.textElement.color);
    _isBold = widget.textElement.isBold;
    _isItalic = widget.textElement.isItalic;
    _isUnderline = widget.textElement.isUnderline;
    _fontSize = widget.textElement.fontSize;
  }

  void _updateStyle() {
    final updatedText = widget.textElement.copyWith(
      color: _selectedColor.toARGB32(),
      isBold: _isBold,
      isItalic: _isItalic,
      isUnderline: _isUnderline,
      fontSize: _fontSize,
    );
    widget.onStyleChanged(updatedText);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Calculate screen position
    final screenX = widget.textElement.x * widget.zoom + widget.canvasOffset.dx;
    final screenY = widget.textElement.y * widget.zoom + widget.canvasOffset.dy;

    // Position popup above the text
    final popupY = screenY - 160;

    final brightness = Theme.of(context).brightness;

    return Positioned(
      left: screenX,
      top: popupY < 20 ? screenY + 40 : popupY,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {}, // Absorb pointer events
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 240,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: DrawingShadows.floating(brightness),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        widget.stickerMode ? 'Emoji Boyutu' : 'Metin Stili',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: PhosphorIcon(StarNoteIcons.close, size: 18, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Color Section (hidden in sticker mode)
                if (!widget.stickerMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Renk',
                          style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        UnifiedColorPicker(
                          selectedColor: _selectedColor,
                          onColorSelected: (color) {
                            setState(() => _selectedColor = color);
                            _updateStyle();
                          },
                          chipSize: 28,
                          spacing: 8,
                        ),
                      ],
                    ),
                  ),

                // Font Size Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Boyut',
                            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const Spacer(),
                          Text(
                            '${_fontSize.round()}',
                            style: textTheme.labelMedium?.copyWith(color: cs.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        ),
                        child: Slider(
                          value: _fontSize,
                          min: widget.stickerMode ? 24 : 8,
                          max: widget.stickerMode ? 200 : 72,
                          onChanged: (value) {
                            setState(() => _fontSize = value);
                            _updateStyle();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Style Buttons Section (hidden in sticker mode)
                if (!widget.stickerMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stil',
                        style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StyleButton(
                            icon: Icons.format_bold,
                            label: 'B',
                            isSelected: _isBold,
                            onTap: () {
                              setState(() => _isBold = !_isBold);
                              _updateStyle();
                            },
                          ),
                          const SizedBox(width: 8),
                          _StyleButton(
                            icon: Icons.format_italic,
                            label: 'I',
                            isSelected: _isItalic,
                            fontStyle: FontStyle.italic,
                            onTap: () {
                              setState(() => _isItalic = !_isItalic);
                              _updateStyle();
                            },
                          ),
                          const SizedBox(width: 8),
                          _StyleButton(
                            icon: Icons.format_underlined,
                            label: 'U',
                            isSelected: _isUnderline,
                            decoration: TextDecoration.underline,
                            onTap: () {
                              setState(() => _isUnderline = !_isUnderline);
                              _updateStyle();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Style toggle button (B, I, U)
class _StyleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final FontStyle? fontStyle;
  final TextDecoration? decoration;
  final VoidCallback onTap;

  const _StyleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.fontStyle,
    this.decoration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: label == 'B' ? FontWeight.bold : FontWeight.normal,
              fontStyle: fontStyle,
              decoration: decoration,
              color: isSelected ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
