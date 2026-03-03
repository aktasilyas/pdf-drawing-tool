/// ElyaNotes Sidebar Tile - Settings-style tile for sidebar navigation
library;

import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Settings-style sidebar tile with circle icon background.
class SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SidebarTile({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.enabled = true,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.accent : AppColors.primary;
    final textColor = !enabled
        ? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
        : isSelected
            ? selectedColor
            : (isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight);
    final iconColor = !enabled
        ? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
        : isSelected
            ? selectedColor
            : (isDark ? AppColors.primaryDarkMode : AppColors.primary);
    final iconBg = isDark
        ? AppColors.surfaceContainerHighDark
        : AppColors.surfaceContainerHighLight;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        color: isSelected
            ? selectedColor.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration:
                  BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
