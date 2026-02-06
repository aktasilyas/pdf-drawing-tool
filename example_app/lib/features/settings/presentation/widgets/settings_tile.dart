/// StarNote Settings Tile - Design system list tile for settings
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Settings list tile widget
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showArrow;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = enabled
        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);
    final subtitleColor = enabled
        ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);
    final iconColor = enabled
        ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.md, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(color: textColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      style: AppTypography.caption.copyWith(color: subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showArrow && onTap != null)
              Icon(Icons.chevron_right,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }
}
