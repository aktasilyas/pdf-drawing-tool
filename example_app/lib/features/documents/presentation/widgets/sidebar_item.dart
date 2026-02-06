/// StarNote Sidebar Item Widget
library;

import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Sidebar item widget
///
/// Modern tasarım:
/// - Selected: sol kenar 3px primary bar + hafif tint arka plan
/// - Dark theme tam uyumlu
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Selected background: çok hafif primary tint (bembeyaz değil!)
    final selectedBg = isDark
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.08);

    // Icon color: custom veya seçime göre
    final effectiveIconColor = iconColor ??
        (isSelected ? AppColors.primary : textSecondary);

    final iconSz = isSubfolder ? AppIconSize.sm : AppIconSize.md;

    return Padding(
      padding: EdgeInsets.only(
        left: isSubfolder ? AppSpacing.xl : AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xxs,
        bottom: AppSpacing.xxs,
      ),
      child: Stack(
        children: [
          // Main content
          Material(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              hoverColor: isDark
                  ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                  : AppColors.surfaceVariantLight.withValues(alpha: 0.5),
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? selectedIcon : icon,
                      size: iconSz,
                      color: effectiveIconColor,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: (isSubfolder
                                ? AppTypography.bodyMedium
                                : AppTypography.titleMedium)
                            .copyWith(
                          color: isSelected ? AppColors.primary : textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Selected indicator: sol kenar 3px primary bar
          if (isSelected)
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
