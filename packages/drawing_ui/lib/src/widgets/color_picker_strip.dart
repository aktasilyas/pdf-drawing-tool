import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/compact_color_picker.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';

/// Horizontal scrollable color strip with a palette button.
///
/// Shows a row of square color chips that scroll horizontally,
/// plus a fixed palette icon on the right that opens [CompactColorPicker].
class ColorPickerStrip extends StatelessWidget {
  const ColorPickerStrip({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colors,
    this.chipSize = 20.0,
    this.isHighlighter = false,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  /// Colors to display. Defaults to [ColorPresets.popular20].
  final List<Color>? colors;

  /// Size of each color square chip.
  final double chipSize;

  /// When true, CompactColorPicker shows opacity slider.
  final bool isHighlighter;

  @override
  Widget build(BuildContext context) {
    final palette = colors ?? ColorPresets.popular20;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final color in palette)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _ColorSquare(
                      color: color,
                      size: chipSize,
                      isSelected: _colorsMatch(color, selectedColor),
                      onTap: () => onColorSelected(color),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        _PaletteIconButton(
          onTap: () => _showColorPalette(context),
        ),
      ],
    );
  }

  void _showColorPalette(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Material(
          color: Colors.black.withValues(alpha: 137.0 / 255.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => overlayEntry.remove(),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 320,
                    maxHeight:
                        MediaQuery.of(overlayContext).size.height * 0.85,
                  ),
                  child: CompactColorPicker(
                    selectedColor: selectedColor,
                    onColorSelected: (color) {
                      onColorSelected(color);
                      overlayEntry.remove();
                    },
                    showOpacity: isHighlighter,
                    onClose: () => overlayEntry.remove(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  static bool _colorsMatch(Color a, Color b) {
    return (a.r * 255.0).round().clamp(0, 255) ==
            (b.r * 255.0).round().clamp(0, 255) &&
        (a.g * 255.0).round().clamp(0, 255) ==
            (b.g * 255.0).round().clamp(0, 255) &&
        (a.b * 255.0).round().clamp(0, 255) ==
            (b.b * 255.0).round().clamp(0, 255);
  }
}

/// Small square color chip.
class _ColorSquare extends StatelessWidget {
  const _ColorSquare({
    required this.color,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : (color.computeLuminance() > 0.8
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Center(
                child: PhosphorIcon(
                  StarNoteIcons.check,
                  size: size * 0.6,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}

/// Fixed palette icon button on the right side of the strip.
class _PaletteIconButton extends StatelessWidget {
  const _PaletteIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: PhosphorIcon(
            StarNoteIcons.palette,
            size: 16,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
