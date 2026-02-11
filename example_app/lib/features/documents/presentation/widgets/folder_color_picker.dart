/// StarNote Folder Color Picker Dialog
///
/// Klasör renk seçici dialog'u.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Folder color picker dialog
class FolderColorPicker extends StatelessWidget {
  final int currentColor;

  const FolderColorPicker({
    super.key,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      title: Text(
        'Renk Seç',
        style: AppTypography.titleLarge.copyWith(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.center,
          children: AppColors.folderColors.map((color) {
            final colorValue = color.value;
            final isSelected = colorValue == currentColor;
            return _ColorItem(
              color: color,
              isSelected: isSelected,
              onTap: () => Navigator.of(context).pop(colorValue),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}

/// Individual color item in the picker
class _ColorItem extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorItem({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: AppIconSize.md,
              )
            : null,
      ),
    );
  }
}

/// Shows the folder color picker dialog and returns the selected color value
Future<int?> showFolderColorPicker({
  required BuildContext context,
  required int currentColor,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => FolderColorPicker(currentColor: currentColor),
  );
}
