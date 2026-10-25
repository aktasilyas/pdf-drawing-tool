/// ElyaNotes Settings Tile - Design system list tile for settings
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
    final palette = context.palette;
    final textColor = enabled ? palette.textPrimary : palette.textDisabled;
    final subtitleColor = enabled ? palette.textMuted : palette.textDisabled;
    final iconColor = enabled ? palette.accent : palette.textDisabled;
    final iconBgColor =
        enabled ? palette.surfaceElevated : palette.accentContainer;

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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppIconSize.sm, color: iconColor),
            ),
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
                      style:
                          AppTypography.caption.copyWith(color: subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showArrow && onTap != null)
              Icon(Icons.chevron_right, color: palette.textDisabled),
          ],
        ),
      ),
    );
  }
}
