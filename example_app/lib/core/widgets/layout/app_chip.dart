/// StarNote Design System - AppChip Component
///
/// Chip/tag komponenti.
///
/// Kullanım:
/// ```dart
/// AppChip(
///   label: 'Flutter',
///   icon: Icons.code,
///   onTap: () => select(),
/// )
///
/// AppChip(
///   label: 'Seçili',
///   isSelected: true,
///   onDelete: () => remove(),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import '../../theme/tokens/index.dart';

/// StarNote chip komponenti.
///
/// Seçilebilir, silinebilir tag/chip.
class AppChip extends StatelessWidget {
  /// Chip label'ı.
  final String label;

  /// Sol taraftaki icon (opsiyonel).
  final IconData? icon;

  /// Chip rengi (null ise tema rengi).
  final Color? color;

  /// Seçili durumu.
  final bool isSelected;

  /// Tıklama callback'i.
  final VoidCallback? onTap;

  /// Silme callback'i (varsa X butonu gösterilir).
  final VoidCallback? onDelete;

  const AppChip({
    required this.label,
    this.icon,
    this.color,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Material(
      color: isSelected ? effectiveColor : AppColors.surfaceVariantLight,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 32,
          padding: EdgeInsets.symmetric(
            horizontal: onDelete != null ? AppSpacing.sm : AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppIconSize.sm,
                  color: _getContentColor(effectiveColor),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: _getContentColor(effectiveColor),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Icon(
                    Icons.close,
                    size: AppIconSize.sm,
                    color: _getContentColor(effectiveColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getContentColor(Color chipColor) {
    return isSelected ? AppColors.onPrimary : AppColors.textPrimaryLight;
  }
}
