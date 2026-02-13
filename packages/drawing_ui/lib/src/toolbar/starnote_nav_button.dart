import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/theme/theme.dart';

/// Professional navigation button with consistent sizing and feedback.
///
/// Used in [TopNavigationBar] and reusable in other toolbars.
/// Visual size is [size] (default 36dp) with 48dp touch target via padding.
class StarNoteNavButton extends StatelessWidget {
  const StarNoteNavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.isDisabled = false,
    this.size = 36.0,
    this.iconSize,
    this.badge,
  });

  /// Phosphor icon to display.
  final IconData icon;

  /// Tooltip text shown on hover/long-press.
  final String tooltip;

  /// Callback when button is pressed.
  final VoidCallback onPressed;

  /// Whether this button is in active/selected state.
  final bool isActive;

  /// Whether this button is disabled (greyed out, not tappable).
  final bool isDisabled;

  /// Visual size of the button container (default 36dp).
  final double size;

  /// Override icon size (defaults to [StarNoteIcons.navSize]).
  final double? iconSize;

  /// Optional badge widget (e.g. notification dot).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconSize = iconSize ?? StarNoteIcons.navSize;

    final iconColor = isDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : isActive
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;

    final bgColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: badge != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      PhosphorIcon(icon, size: effectiveIconSize, color: iconColor),
                      Positioned(top: 4, right: 4, child: badge!),
                    ],
                  )
                : PhosphorIcon(icon, size: effectiveIconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}
