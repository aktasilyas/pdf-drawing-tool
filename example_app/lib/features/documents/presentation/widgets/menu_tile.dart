/// Menu tile for document/folder bottom sheet menus.
///
/// Matches settings tile and sidebar tile icon design:
/// circular background with themed icon color.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Bottom sheet menu tile with circular icon background.
///
/// Consistent with [SettingsTile] icon styling.
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  const MenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive ? AppColors.error : context.palette.accent;
    final iconBgColor = isDestructive
        ? AppColors.error.withValues(alpha: 0.1)
        : context.palette.surfaceElevated;
    final textColor =
        isDestructive ? AppColors.error : context.palette.textPrimary;

    return InkWell(
      onTap: onTap,
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
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
