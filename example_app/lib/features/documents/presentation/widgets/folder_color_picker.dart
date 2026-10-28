/// ElyaNotes Folder Color Picker Dialog
///
/// Klasör renk seçici dialog'u.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Folder color picker dialog
class FolderColorPicker extends StatelessWidget {
  final int currentColor;

  const FolderColorPicker({
    super.key,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: context.palette.surface,
      title: Text(
        l10n.librarySelectColor,
        style: AppTypography.titleLarge.copyWith(
          color: context.palette.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.center,
          children: AppColors.folderColors.map((color) {
            final colorValue = color.toARGB32();
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
          child: Text(l10n.commonCancel),
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
            color:
                isSelected ? context.palette.textPrimary : Colors.transparent,
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
                color: AppColors.onPrimary,
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
