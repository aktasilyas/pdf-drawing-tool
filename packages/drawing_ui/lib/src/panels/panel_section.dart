import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Section within a tool panel.
class PanelSection extends StatelessWidget {
  const PanelSection({
    super.key,
    required this.title,
    required this.child,
    this.isLocked = false,
    this.onLockedTap,
  });

  /// Title of the section.
  final String title;

  /// Content of the section.
  final Widget child;

  /// Whether this section is locked (premium feature).
  final bool isLocked;

  /// Callback when locked section is tapped.
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: ChromeSpacing.xs + ChromeSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChromeSpacing.xs + ChromeSpacing.xxs,
                  vertical: ChromeSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(ElyanotesIcons.lock,
                        size: 10, color: colorScheme.tertiary),
                    const SizedBox(width: ChromeSpacing.xxs),
                    Text(
                      'PRO',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ChromeSpacing.sm + ChromeSpacing.xxs),
        if (isLocked)
          _LockedSectionOverlay(onTap: onLockedTap, child: child)
        else
          child,
      ],
    );
  }
}

/// Overlay for locked (premium) sections.
class _LockedSectionOverlay extends StatelessWidget {
  const _LockedSectionOverlay({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Blurred content
          Opacity(
            opacity: 0.3,
            child: IgnorePointer(child: child),
          ),
          // Lock overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(ElyanotesIcons.lock,
                        color: colorScheme.tertiary, size: 24),
                    const SizedBox(height: ChromeSpacing.xs),
                    Text(
                      'Premium',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.tertiary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
