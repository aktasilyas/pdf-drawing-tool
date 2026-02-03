/// StarNote Sidebar Item Widget
library;

import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Sidebar item widget
class SidebarItem extends StatelessWidget {
  final IconData icon, selectedIcon;
  final String label;
  final bool isSelected, isSubfolder;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    this.isSubfolder = false,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ??
        (isSelected ? AppColors.primary : AppColors.textSecondaryLight);
    final iconSz = isSubfolder ? AppIconSize.sm : AppIconSize.md;

    return Padding(
      padding: EdgeInsets.only(
        left: isSubfolder ? AppSpacing.xl : AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xxs,
        bottom: AppSpacing.xxs,
      ),
      child: Material(
        color: isSelected ? AppColors.surfaceVariantLight : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(isSelected ? selectedIcon : icon, size: iconSz, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: (isSubfolder ? AppTypography.bodyMedium : AppTypography.titleMedium)
                        .copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
