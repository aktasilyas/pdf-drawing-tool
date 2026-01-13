import 'package:flutter/material.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/color_chip.dart';

/// A grid of color chips for color selection.
///
/// Displays available colors in a wrap layout and highlights the selected color.
class ColorChipsGrid extends StatelessWidget {
  const ColorChipsGrid({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.crossAxisCount = 6,
    this.spacing = 8.0,
    this.chipSize,
    this.showOpacity = false,
  });

  /// Available colors to display.
  final List<Color> colors;

  /// Currently selected color.
  final Color selectedColor;

  /// Callback when a color is selected.
  final ValueChanged<Color> onColorSelected;

  /// Number of columns in the grid.
  final int crossAxisCount;

  /// Spacing between chips.
  final double spacing;

  /// Size of each chip (defaults to theme's colorChipSize).
  final double? chipSize;

  /// Whether to show opacity indicator (for semi-transparent colors like highlighters).
  final bool showOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final actualChipSize = chipSize ?? theme.colorChipSize;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: colors.map((color) {
        return ColorChip(
          color: color,
          isSelected: _colorsEqual(color, selectedColor),
          onTap: () => onColorSelected(color),
          size: actualChipSize,
          showOpacity: showOpacity,
        );
      }).toList(),
    );
  }

  /// Compare colors accounting for alpha differences in highlighter colors.
  bool _colorsEqual(Color a, Color b) {
    // Compare RGB values (ignore alpha for highlighter colors)
    return a.red == b.red &&
        a.green == b.green &&
        a.blue == b.blue &&
        (a.alpha == b.alpha || a.alpha == 0x80 || b.alpha == 0x80);
  }
}
