/// Recently used colours row for the colour picker.
import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/chrome_palette.dart';
import 'package:drawing_ui/src/widgets/color_swatch_target.dart';

/// Recent Colors Row
class RecentColorsRow extends StatelessWidget {
  const RecentColorsRow({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final accent = ChromePalette.of(context).accent;
    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: colors.take(12).map((color) {
        final isSelected = _colorsMatch(color, selectedColor);
        return ColorSwatchTarget(
          color: color,
          isSelected: isSelected,
          onTap: () => onColorSelected(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}
