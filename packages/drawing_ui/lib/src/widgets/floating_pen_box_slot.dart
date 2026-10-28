import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/color_chip.dart'
    show colorHex;
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';

/// One preset pen in the `FloatingPenBox`.
///
/// [boxAxis] is the direction the box lays its pens out in:
/// - [Axis.vertical] (a column): the pen lies flat with its tip to the right
///   and slides right when selected.
/// - [Axis.horizontal] (a row): the pen stands with its tip down and slides
///   down when selected.
///
/// Unselected pens show only the tip and the colour band.
class FloatingPenBoxSlot extends StatelessWidget {
  /// Creates a slot for [preset].
  const FloatingPenBoxSlot({
    super.key,
    required this.preset,
    required this.boxAxis,
    required this.isSelected,
    required this.isEditMode,
    required this.onTap,
    required this.onDelete,
    this.onDoubleTap,
  });

  /// The preset shown in this slot.
  final PenPreset preset;

  /// Layout direction of the surrounding box.
  final Axis boxAxis;

  /// Whether this preset is the active one.
  final bool isSelected;

  /// Whether the box shows delete badges.
  final bool isEditMode;

  /// Activates the preset.
  final VoidCallback onTap;

  /// Removes the preset (edit mode only).
  final VoidCallback onDelete;

  /// Opens the preset's editor.
  final VoidCallback? onDoubleTap;

  /// Long side of the slot (along the pen).
  static const double _slotLength = 56;

  /// Short side of the slot; the minimum touch target.
  static const double _slotBreadth = ChromeSizes.minTouchTarget;

  static const double _penSize = 50;

  /// Pen offset along its length: selected pens slide out to show more.
  static const double _selectedOffset = 6;
  static const double _restingOffset = -16;

  /// Pens in a row are flipped 180° so the tip points down.
  static const double _flipAngle = 3.14159;

  static const double _badgeSize = 14;
  static const double _badgeIconSize = 10;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isColumn = boxAxis == Axis.vertical;
    final slide = isSelected ? _selectedOffset : _restingOffset;
    const centred = (_slotBreadth - _penSize) / 2;
    final strings = context.drawingStrings;
    final label = '${preset.toolType.label(strings)}, '
        '${strings.toolbar.color(colorHex(preset.color))}';

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: isColumn ? _slotLength : _slotBreadth,
          height: isColumn ? _slotBreadth : _slotLength,
          decoration: isSelected
              ? BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(ChromeRadius.sm),
                )
              : null,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              AnimatedPositioned(
                duration: ChromeDurations.fast,
                curve: Curves.easeOutCubic,
                left: isColumn ? slide : centred,
                top: isColumn ? centred : slide,
                width: _penSize,
                height: _penSize,
                child: isColumn
                    ? _pen(PenOrientation.horizontal)
                    : Transform.rotate(
                        angle: _flipAngle,
                        child: _pen(PenOrientation.vertical),
                      ),
              ),
              if (isEditMode)
                Positioned(
                  right: ChromeSpacing.xxs,
                  top: isColumn ? ChromeSpacing.xxs : null,
                  bottom: isColumn ? null : ChromeSpacing.xxs,
                  child: Semantics(
                    container: true,
                    button: true,
                    label: context.drawingStrings.canvas.removePen,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: _badgeSize,
                        height: _badgeSize,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        // Moved as-is; token migration is tracked separately.
                        child: PhosphorIcon(
                          ElyanotesIcons.minus,
                          size: _badgeIconSize,
                          color: Colors.white,
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

  Widget _pen(PenOrientation orientation) {
    return ToolPenIcon(
      toolType: preset.toolType,
      color: preset.color,
      isSelected: false,
      size: _penSize,
      orientation: orientation,
    );
  }
}
