import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// The collapsed `FloatingPenBox`: a brush icon with a badge counting the
/// presets. Tapping it expands the box.
class FloatingPenBoxCollapsed extends StatelessWidget {
  /// Creates the collapsed box showing [count] presets.
  const FloatingPenBoxCollapsed({
    super.key,
    required this.count,
    required this.onExpand,
  });

  /// Number of presets in the box.
  final int count;

  /// Expands the box.
  final VoidCallback onExpand;

  static const double _size = 40;
  static const double _iconSize = 18;
  static const double _badgeSize = 14;
  static const double _badgeFontSize = 8;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Kalem kutusu, $count kalem',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onExpand,
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PhosphorIcon(
                ElyanotesIcons.paintBrush,
                size: _iconSize,
                color: colorScheme.onSurfaceVariant,
              ),
              Positioned(
                right: ChromeSpacing.xxs,
                bottom: ChromeSpacing.xxs,
                child: Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      // Moved as-is; token migration is tracked separately.
                      style: const TextStyle(
                        fontSize: _badgeFontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit toggle and collapse button at the end of an expanded
/// `FloatingPenBox`: below the pens in a column ([Axis.vertical]), to their
/// right in a row ([Axis.horizontal]).
class FloatingPenBoxControls extends StatelessWidget {
  /// Creates the controls for a box laid out along [boxAxis].
  const FloatingPenBoxControls({
    super.key,
    required this.boxAxis,
    required this.isEditMode,
    required this.onToggleEditMode,
    required this.onCollapse,
  });

  /// Layout direction of the surrounding box.
  final Axis boxAxis;

  /// Whether the box shows delete badges.
  final bool isEditMode;

  /// Enters or leaves edit mode.
  final VoidCallback onToggleEditMode;

  /// Collapses the box.
  final VoidCallback onCollapse;

  /// Off-grid inset kept from the original layout.
  static const double _inset = 6;
  static const double _editIconSize = 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isColumn = boxAxis == Axis.vertical;

    final editButton = Semantics(
      button: true,
      label: isEditMode ? 'Düzenlemeyi bitir' : 'Kalem kutusunu düzenle',
      child: GestureDetector(
        onTap: onToggleEditMode,
        child: PhosphorIcon(
          isEditMode ? ElyanotesIcons.check : ElyanotesIcons.editPencil,
          size: _editIconSize,
          color:
              isEditMode ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
    final collapseButton = Semantics(
      button: true,
      label: 'Kalem kutusunu daralt',
      child: GestureDetector(
        onTap: onCollapse,
        child: PhosphorIcon(
          isColumn ? ElyanotesIcons.caretUp : ElyanotesIcons.chevronLeft,
          size: ChromeIconSizes.sm,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );

    if (isColumn) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _inset,
          vertical: ChromeSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            editButton,
            const SizedBox(width: ChromeSpacing.md),
            collapseButton,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ChromeSpacing.xs,
        vertical: _inset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          editButton,
          const SizedBox(height: ChromeSpacing.sm),
          collapseButton,
        ],
      ),
    );
  }
}
