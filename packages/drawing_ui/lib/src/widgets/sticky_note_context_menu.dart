import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/l10n/canvas_strings.dart';
import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/theme/chrome_palette.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Fill colours offered by the sticky-note menu.
///
/// [argb] is document data (stored on the note), not a chrome colour.
enum StickyNoteColor {
  yellow(0xFFFFF3CD),
  pink(0xFFF8D7DA),
  blue(0xFFD1ECF1),
  green(0xFFD4EDDA),
  orange(0xFFFFE0CC),
  purple(0xFFE8D5F5);

  const StickyNoteColor(this.argb);

  /// ARGB value written to the note.
  final int argb;

  /// Localized name read by screen readers.
  String label(CanvasStrings s) => switch (this) {
        StickyNoteColor.yellow => s.stickyNoteColorYellow,
        StickyNoteColor.pink => s.stickyNoteColorPink,
        StickyNoteColor.blue => s.stickyNoteColorBlue,
        StickyNoteColor.green => s.stickyNoteColorGreen,
        StickyNoteColor.orange => s.stickyNoteColorOrange,
        StickyNoteColor.purple => s.stickyNoteColorPurple,
      };
}

/// Top-left corner of a [menuSize] menu for a note at [noteRect] (screen
/// space), kept [margin] inside [bounds].
///
/// The menu is centred on the note and sits [gap] above it; when there is no
/// room above it flips below the note. Both axes are then clamped so the menu
/// never leaves [bounds].
Offset stickyNoteMenuOrigin({
  required Rect noteRect,
  required Size menuSize,
  required Size bounds,
  double gap = ChromeSpacing.sm,
  double margin = ChromeSpacing.sm,
}) {
  final maxLeft = math.max(margin, bounds.width - menuSize.width - margin);
  final left =
      (noteRect.center.dx - menuSize.width / 2).clamp(margin, maxLeft);
  var top = noteRect.top - gap - menuSize.height;
  if (top < margin) top = noteRect.bottom + gap;
  final maxTop = math.max(margin, bounds.height - menuSize.height - margin);
  return Offset(left, top.clamp(margin, maxTop));
}

/// Sticky-note context menu placed next to [noteRect] inside the parent
/// [Stack] (the canvas), never off screen.
///
/// Only the menu card takes pointer events; the rest of the stack area
/// passes them through to the canvas.
class StickyNoteContextMenu extends StatelessWidget {
  const StickyNoteContextMenu({
    super.key,
    required this.noteRect,
    required this.selectedColor,
    required this.onColorChange,
    required this.onDelete,
  });

  /// The selected note's rectangle in screen (stack) coordinates.
  final Rect noteRect;

  /// The note's current ARGB colour; the matching dot is shown selected.
  final int selectedColor;
  final ValueChanged<int> onColorChange;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _StickyNoteMenuLayout(noteRect),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {},
          child: StickyNoteMenuCard(
            selectedColor: selectedColor,
            onColorChange: onColorChange,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }
}

class _StickyNoteMenuLayout extends SingleChildLayoutDelegate {
  const _StickyNoteMenuLayout(this.noteRect);

  final Rect noteRect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      stickyNoteMenuOrigin(
        noteRect: noteRect,
        menuSize: childSize,
        bounds: size,
      );

  @override
  bool shouldRelayout(_StickyNoteMenuLayout oldDelegate) =>
      oldDelegate.noteRect != noteRect;
}

/// The menu card: a row of colour swatches above a delete action.
///
/// Every target is [ChromeSizes.minTouchTarget] square or tall, and each
/// swatch is a labelled button with a selected state for screen readers.
class StickyNoteMenuCard extends StatelessWidget {
  const StickyNoteMenuCard({
    super.key,
    required this.selectedColor,
    required this.onColorChange,
    required this.onDelete,
  });

  final int selectedColor;
  final ValueChanged<int> onColorChange;
  final VoidCallback onDelete;

  static const double _swatchSize = 28;
  static const double _rowWidth =
      ChromeSizes.minTouchTarget * 6; // one target per StickyNoteColor

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final theme = Theme.of(context);
    final strings = context.drawingStrings;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(ChromeSpacing.xs),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(ChromeRadius.lg),
          boxShadow: DrawingShadows.floating(theme.brightness),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in StickyNoteColor.values)
                  _swatch(palette, c, c.label(strings.canvas)),
              ],
            ),
            SizedBox(
              width: _rowWidth,
              height: 1,
              child: ColoredBox(color: palette.border),
            ),
            Semantics(
              container: true,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: SizedBox(
                  width: _rowWidth,
                  height: ChromeSizes.minTouchTarget,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        ElyanotesIcons.trash,
                        size: ChromeIconSizes.sm,
                        color: palette.danger,
                      ),
                      const SizedBox(width: ChromeSpacing.xs),
                      Text(
                        strings.selection.delete,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: palette.danger),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(ChromePalette palette, StickyNoteColor c, String label) {
    final selected = c.argb == selectedColor;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onColorChange(c.argb),
        child: SizedBox(
          width: ChromeSizes.minTouchTarget,
          height: ChromeSizes.minTouchTarget,
          child: Center(
            child: Container(
              width: _swatchSize,
              height: _swatchSize,
              decoration: BoxDecoration(
                color: Color(c.argb),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? palette.accent : palette.border,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
