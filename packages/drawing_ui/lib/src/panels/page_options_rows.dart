import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/theme/theme.dart';

/// Header widget for page options panel.
class PageOptionsHeader extends StatelessWidget {
  const PageOptionsHeader(
      {super.key, required this.title, this.compact = false});
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? ChromeSpacing.lg : 20,
        vertical: compact ? 8 : 12,
      ),
      child: Text(
        title,
        style: compact
            ? textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              )
            : textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
      ),
    );
  }
}

/// A single menu item row in the page options panel.
class PageOptionsMenuItem extends StatelessWidget {
  const PageOptionsMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.isDestructive = false,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;

    // Icon color
    final Color iconColor;
    // Icon background color
    final Color iconBgColor;

    if (disabled) {
      iconColor = cs.onSurface.withValues(alpha: 0.38);
      iconBgColor = cs.onSurface.withValues(alpha: 0.05);
    } else if (isDestructive) {
      iconColor = cs.error;
      iconBgColor = cs.error.withValues(alpha: 0.1);
    } else {
      iconColor = cs.primary;
      iconBgColor = cs.surfaceContainerHigh;
    }

    // Label color: destructive/disabled affect label, normal stays onSurface
    final labelColor = disabled
        ? cs.onSurface.withValues(alpha: 0.38)
        : isDestructive
            ? cs.error
            : cs.onSurface;

    final circleSize = compact ? 30.0 : 36.0;
    final iconSize = compact ? 18.0 : 20.0;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: compact ? 40 : 48,
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: compact ? ChromeSpacing.lg : 20),
          child: Row(
            children: [
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(icon, size: iconSize, color: iconColor),
                ),
              ),
              const SizedBox(width: ChromeSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: compact
                      ? Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 13, color: labelColor)
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 15, color: labelColor),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header for settings area.
class PageOptionsSectionHeader extends StatelessWidget {
  const PageOptionsSectionHeader(
      {super.key, required this.title, this.compact = false});
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? ChromeSpacing.lg : 20,
          compact ? 2 : 4, compact ? ChromeSpacing.lg : 20, compact ? 1 : 2),
      child: Text(
        title,
        style: compact
            ? Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                )
            : Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
      ),
    );
  }
}
