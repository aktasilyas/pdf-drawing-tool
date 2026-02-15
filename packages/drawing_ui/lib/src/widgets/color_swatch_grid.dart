import 'package:flutter/material.dart';

/// Samsung Notes-style color swatch grid.
/// Columns: gray + 9 hue steps. Rows: light → dark.
class ColorSwatchGrid extends StatelessWidget {
  const ColorSwatchGrid({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  static final List<List<Color>> _grid = _buildGrid();

  static List<List<Color>> _buildGrid() {
    const hues = [0.0, 30.0, 55.0, 120.0, 175.0, 210.0, 240.0, 275.0, 310.0];
    const levels = [
      0.94, 0.86, 0.76, 0.66, 0.56, 0.46, 0.36, 0.26, 0.16, 0.08,
    ];

    return levels.map((l) {
      final gray = HSLColor.fromAHSL(1, 0, 0, l).toColor();
      final colors = hues.map(
        (h) => HSLColor.fromAHSL(1, h, 0.7, l).toColor(),
      );
      return [gray, ...colors];
    }).toList();
  }

  bool _matches(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Subtract 2px for the border (1px each side)
      final cellSize = (constraints.maxWidth - 2) / _grid.first.length;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF424242)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _grid
                .map((row) => Row(
                      children: row.map((color) {
                        final selected = _matches(color, selectedColor);
                        return GestureDetector(
                          onTap: () => onColorSelected(color),
                          child: SizedBox(
                            width: cellSize,
                            height: cellSize,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: color),
                              child: selected
                                  ? Center(
                                      child: Container(
                                        width: cellSize * 0.4,
                                        height: cellSize * 0.4,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ))
                .toList(),
          ),
        ),
      );
    });
  }
}
