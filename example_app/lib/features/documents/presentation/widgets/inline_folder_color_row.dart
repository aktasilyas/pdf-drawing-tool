import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_color_names.dart';
import 'package:example_app/l10n/l10n.dart';

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
        children: AppColors.folderColors.indexed.map((entry) {
          final color = entry.$2;
          final isSelected = color.toARGB32() == selectedColorValue;
          return Semantics(
            label: folderColorName(context.l10n, entry.$1),
            button: true,
            selected: isSelected,
            excludeSemantics: true,
            onTap: () => onChanged(color.toARGB32()),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(color.toARGB32()),
              child: Container(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                alignment: Alignment.center,
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
