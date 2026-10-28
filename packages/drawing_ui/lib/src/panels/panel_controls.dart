import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// A toggle option row for panels.
class PanelToggleRow extends StatelessWidget {
  const PanelToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ChromeSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: enabled ? colorScheme.onSurface : colorScheme.outline,
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// A button row for panel actions.
class PanelActionButton extends StatelessWidget {
  const PanelActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isPrimary
        ? colorScheme.primary
        : isDestructive
            ? colorScheme.error.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerLowest;
    final fgColor = isPrimary
        ? colorScheme.onPrimary
        : isDestructive
            ? colorScheme.error
            : colorScheme.onSurface;

    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: ChromeSizes.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ChromeSpacing.lg,
              vertical: ChromeSpacing.md,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fgColor),
                  const SizedBox(width: ChromeSpacing.sm),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable panel close button: a 32dp circular X inside a 48dp target,
/// announced with the localized "close" label.
///
/// Used in tool settings panels (pen, highlighter, eraser, etc.)
/// to provide an explicit close action.
class PanelCloseButton extends StatelessWidget {
  const PanelCloseButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      label: context.drawingStrings.panels.close,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox.square(
        dimension: ChromeSizes.minTouchTarget,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.controlSurface,
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  ElyanotesIcons.close,
                  size: ElyanotesIcons.panelSize,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
