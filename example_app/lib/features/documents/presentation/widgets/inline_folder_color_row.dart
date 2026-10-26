import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Horizontal row of folder colour swatches used by the inline
/// "new folder" section of the move-to-folder dialog.
class InlineFolderColorRow extends StatelessWidget {
  /// ARGB value of the currently selected colour.
  final int selectedColorValue;

  /// Called with the ARGB value of the tapped swatch.
  final ValueChanged<int> onChanged;

  const InlineFolderColorRow({
    super.key,
    required this.selectedColorValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppColors.folderColors.map((color) {
          final isSelected = color.toARGB32() == selectedColorValue;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onChanged(color.toARGB32()),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.onPrimary : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.onPrimary,
                        size: AppIconSize.xs,
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
