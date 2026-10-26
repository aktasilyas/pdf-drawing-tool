/// ElyaNotes Paper Color Palette - Color picker for paper background
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';

/// Paper color palette widget
class PaperColorPalette extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  const PaperColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  /// Available paper colors (ARGB), in palette order.
  static final paperColors = [
    for (final color in PaperColor.palette) color.argb,
  ];

  @override
  Widget build(BuildContext context) {
    final outlineColor = context.palette.border;

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
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.1),
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
                    color: color == 0xFF1A1A1A
                        ? AppColors.onPrimary
                        : AppColors.primary,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
