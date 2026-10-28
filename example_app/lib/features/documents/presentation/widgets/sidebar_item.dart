/// ElyaNotes Sidebar Item Widget
library;

import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Sidebar row: 48 high, flat. Selected = accentContainer fill with accent
/// icon and label; pressed = textPrimary at 6%. No ripple, no side bar.
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
    final palette = context.palette;
    final effectiveIconColor =
        iconColor ?? (isSelected ? palette.accent : palette.textMuted);
    final radius = BorderRadius.circular(AppRadius.md);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      // Merged into one node: the label (plus e.g. a folder's count) is read
      // together with the button role and the selected state.
      child: MergeSemantics(
        child: Semantics(
          button: true,
          selected: isSelected,
          child: Material(
        color: isSelected ? palette.accentContainer : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: palette.textPrimary.withValues(alpha: 0.06),
          child: Container(
            height: AppSpacing.minTouchTarget,
            padding: EdgeInsets.only(
              left: AppSpacing.md + (isSubfolder ? AppSpacing.lg : 0),
              right: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: AppIconSize.md,
                  color: effectiveIconColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected ? palette.accent : palette.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : null,
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
        ),
      ),
    );
  }
}
