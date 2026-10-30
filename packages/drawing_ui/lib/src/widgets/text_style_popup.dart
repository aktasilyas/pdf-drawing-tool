import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/text_style_toggle_button.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';

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

/// Four quick colours plus the palette button: five 48dp targets in a row.
const int _quickColorCount = 4;
const double _swatchSize = 28;
const double _swatchRowInset = ChromeSpacing.sm;
const double _popupWidth =
    (_quickColorCount + 1) * ChromeSizes.minTouchTarget + 2 * _swatchRowInset;

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
    final s = context.drawingStrings;
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
            width: _popupWidth,
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
                        widget.stickerMode
                            ? s.canvas.emojiSize
                            : s.canvas.textStyleTitle,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onClose,
                        tooltip: s.panels.close,
                        constraints: const BoxConstraints.tightFor(
                          width: ChromeSizes.minTouchTarget,
                          height: ChromeSizes.minTouchTarget,
                        ),
                        icon: PhosphorIcon(ElyanotesIcons.close,
                            size: 18, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Color Section (hidden in sticker mode)
                if (!widget.stickerMode) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      s.panels.textColor,
                      style: textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  // The 48dp hit areas pad the 28dp dots by 10dp, so this
                  // row uses a smaller inset and fits on one line.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _swatchRowInset,
                    ),
                    child: UnifiedColorPicker(
                      key: const ValueKey('text-style-colors'),
                      selectedColor: _selectedColor,
                      onColorSelected: (color) {
                        setState(() => _selectedColor = color);
                        _updateStyle();
                      },
                      quickColors: ColorPresets.quickAccess
                          .take(_quickColorCount)
                          .toList(),
                      chipSize: _swatchSize,
                      spacing: 0,
                      compactMoreButton: true,
                    ),
                  ),
                ],

                // Font Size Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            s.panels.size,
                            style: textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const Spacer(),
                          Text(
                            '${_fontSize.round()}',
                            style: textTheme.labelMedium
                                ?.copyWith(color: cs.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                          // 24dp overlay keeps the slider track 48dp tall.
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 24),
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
                          s.panels.textStyle,
                          style: textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextStyleToggleButton(
                              icon: Icons.format_bold,
                              label: 'B', // l10n-ignore
                              semanticLabel: s.panels.bold,
                              isSelected: _isBold,
                              onTap: () {
                                setState(() => _isBold = !_isBold);
                                _updateStyle();
                              },
                            ),
                            const SizedBox(width: 8),
                            TextStyleToggleButton(
                              icon: Icons.format_italic,
                              label: 'I', // l10n-ignore
                              semanticLabel: s.panels.italic,
                              isSelected: _isItalic,
                              fontStyle: FontStyle.italic,
                              onTap: () {
                                setState(() => _isItalic = !_isItalic);
                                _updateStyle();
                              },
                            ),
                            const SizedBox(width: 8),
                            TextStyleToggleButton(
                              icon: Icons.format_underlined,
                              label: 'U', // l10n-ignore
                              semanticLabel: s.panels.underline,
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
