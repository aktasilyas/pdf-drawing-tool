/// StarNote Format Picker Sheet - Bottom sheet for paper format selection
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';

/// Paper format picker bottom sheet
class FormatPickerSheet extends StatelessWidget {
  final PaperSize currentSize;

  const FormatPickerSheet({super.key, required this.currentSize});

  static Future<PaperSize?> show(BuildContext context, PaperSize currentSize) {
    return showModalBottomSheet<PaperSize>(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (ctx) => FormatPickerSheet(currentSize: currentSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Format Seç', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),

            // Orientation
            Text('Yön:', style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondaryLight)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _OrientationChip(
                  label: 'Dikey',
                  icon: Icons.crop_portrait,
                  isSelected: !currentSize.isLandscape,
                  onTap: () => Navigator.pop(context, currentSize.portrait),
                ),
                const SizedBox(width: AppSpacing.sm),
                _OrientationChip(
                  label: 'Yatay',
                  icon: Icons.crop_landscape,
                  isSelected: currentSize.isLandscape,
                  onTap: () => Navigator.pop(context, currentSize.landscape),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Size
            Text('Boyut:', style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondaryLight)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                PaperSizePreset.a4,
                PaperSizePreset.a5,
                PaperSizePreset.a6,
                PaperSizePreset.letter,
                PaperSizePreset.square,
              ].map((preset) {
                final isSelected = currentSize.preset == preset;
                return AppChip(
                  label: _getPresetName(preset),
                  isSelected: isSelected,
                  onTap: () {
                    final newSize = PaperSize.fromPreset(preset);
                    Navigator.pop(
                      context,
                      currentSize.isLandscape ? newSize.landscape : newSize,
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  String _getPresetName(PaperSizePreset preset) {
    switch (preset) {
      case PaperSizePreset.a4: return 'A4';
      case PaperSizePreset.a5: return 'A5';
      case PaperSizePreset.a6: return 'A6';
      case PaperSizePreset.letter: return 'Letter';
      case PaperSizePreset.legal: return 'Legal';
      case PaperSizePreset.square: return 'Kare';
      case PaperSizePreset.widescreen: return 'Geniş';
      case PaperSizePreset.custom: return 'Özel';
    }
  }
}

class _OrientationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrientationChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.sm,
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimaryLight),
            const SizedBox(width: AppSpacing.xs),
            Text(label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.textPrimaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
