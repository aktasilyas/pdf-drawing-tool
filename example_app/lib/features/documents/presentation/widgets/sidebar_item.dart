/// ElyaNotes Sidebar Item Widget
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

    // Dark modda accent (#4A8AF7) kullan — primary (#38434F) koyu bg'de görünmez
    final selectedColor = isDark ? AppColors.accent : AppColors.primary;

    // Theme-aware colors
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Selected background: hafif tint
    final selectedBg = selectedColor.withValues(alpha: 0.12);

    // Icon color: custom veya seçime göre
    final effectiveIconColor = iconColor ??
        (isSelected ? selectedColor : textSecondary);

    final iconSz = isSubfolder ? AppIconSize.sm : AppIconSize.sm;

    return Padding(
      padding: EdgeInsets.only(
        left: isSubfolder ? AppSpacing.xl : AppSpacing.sm,
        right: AppSpacing.sm,
        top: 1,
        bottom: 1,
      ),
      child: Stack(
        children: [
          // Main content
          Material(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              hoverColor: isDark
                  ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                  : AppColors.surfaceVariantLight.withValues(alpha: 0.5),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? selectedIcon : icon,
                      size: iconSz,
                      color: effectiveIconColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        label,
                        style: (isSubfolder
                                ? AppTypography.caption
                                : AppTypography.bodyMedium)
                            .copyWith(
                          color: isSelected ? selectedColor : textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.xs),
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
              top: 6,
              bottom: 6,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
