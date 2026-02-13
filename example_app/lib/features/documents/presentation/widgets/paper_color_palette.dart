/// StarNote Paper Color Palette - Color picker for paper background
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Paper color palette widget
class PaperColorPalette extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  const PaperColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  /// Available paper colors
  static const paperColors = [
    0xFFFFFFFF, // Beyaz
    0xFF1A1A1A, // Siyah (dark mode için)
    0xFFFFF8E7, // Krem
    0xFFF5F5F5, // Açık gri
    0xFFE8F5E9, // Açık yeşil
    0xFFE3F2FD, // Açık mavi
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: paperColors.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : outlineColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: (color == 0xFFFFFFFF || color == 0xFFF5F5F5)
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: AppIconSize.sm,
                    color: color == 0xFF1A1A1A ? Colors.white : AppColors.primary,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
