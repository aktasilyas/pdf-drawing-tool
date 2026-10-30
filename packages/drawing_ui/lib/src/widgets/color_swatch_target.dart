/// Accessible hit area for a single colour swatch.
import 'package:flutter/material.dart';

import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/widgets/color_chip.dart' show colorHex;

/// Wraps a swatch visual in a [ChromeSizes.minTouchTarget] square and
/// announces it as a selectable button labelled with the colour
/// (`toolbar.color('#RRGGBB')`).
///
/// The visual keeps its own size; only the hit area grows. Child semantics
/// are excluded so TalkBack reads one node per swatch.
class ColorSwatchTarget extends StatelessWidget {
  const ColorSwatchTarget({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.onDoubleTap,
  });

  /// Colour described to screen readers.
  final Color color;

  /// Reported as the node's `selected` state.
  final bool isSelected;

  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  /// The swatch visual, centred in the hit area.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: context.drawingStrings.toolbar.color(colorHex(color)),
      excludeSemantics: true,
      // excludeSemantics drops the detector's action; expose it here so
      // TalkBack's double-tap activates the swatch.
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: SizedBox.square(
          dimension: ChromeSizes.minTouchTarget,
          child: Center(child: child),
        ),
      ),
    );
  }
}
