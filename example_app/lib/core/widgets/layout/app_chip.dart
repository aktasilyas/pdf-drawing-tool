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

import 'package:example_app/core/theme/index.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? AppColors.primary;
    final unselectedBg = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    return Material(
      color: isSelected ? effectiveColor : unselectedBg,
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
                  color: _getContentColor(effectiveColor, isDark: isDark),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: _getContentColor(effectiveColor, isDark: isDark),
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
                    color: _getContentColor(effectiveColor, isDark: isDark),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getContentColor(Color chipColor, {bool isDark = false}) {
    if (isSelected) return AppColors.onPrimary;
    return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  }
}
