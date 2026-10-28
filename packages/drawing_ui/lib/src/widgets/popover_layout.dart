import 'package:flutter/painting.dart';

import 'package:drawing_ui/src/theme/theme.dart';

/// Where a popover panel opens relative to its anchor.
enum PopoverPlacement { below, above, right }

/// Pure positioning math for [PopoverController] panels
/// (docs/specs/52-editor-chrome.md, section 4 "Popover panel").
///
/// Opens below the anchor, flips above it when less than [minSpace] is free
/// below, and opens to the right when neither vertical direction has room.
/// Vertical panels are centred on the anchor and clamped [edge] from the
/// screen sides.
class PopoverLayout {
  const PopoverLayout({
    required this.anchor,
    required this.screenSize,
    required this.maxWidth,
  });

  /// Distance kept from the screen edges.
  static const double edge = ChromeSpacing.md;

  /// Gap between anchor and panel.
  static const double gap = ChromeSpacing.sm;

  /// Space a vertical placement needs before the panel flips.
  static const double minSpace = 360;

  /// Anchor bounds in global coordinates.
  final Rect anchor;

  /// Size of the overlay the panel is laid out in.
  final Size screenSize;

  /// Maximum panel width.
  final double maxWidth;

  /// The direction the panel opens in.
  PopoverPlacement get placement {
    final spaceBelow = screenSize.height - anchor.bottom - gap - edge;
    final spaceAbove = anchor.top - gap - edge;
    if (spaceBelow >= minSpace) return PopoverPlacement.below;
    if (spaceAbove >= minSpace) return PopoverPlacement.above;
    return PopoverPlacement.right;
  }

  /// Largest height the panel may take in its [placement].
  double get maxHeight => switch (placement) {
        PopoverPlacement.below =>
          screenSize.height - anchor.bottom - gap - edge,
        PopoverPlacement.above => anchor.top - gap - edge,
        PopoverPlacement.right => screenSize.height - edge * 2,
      };

  /// Left edge of the panel.
  double get left => switch (placement) {
        PopoverPlacement.right => anchor.right + gap,
        _ => (anchor.center.dx - maxWidth / 2)
            .clamp(edge, screenSize.width - maxWidth - edge)
            .toDouble(),
      };

  /// Top edge of the panel; null when it is pinned by its [bottom].
  double? get top => switch (placement) {
        PopoverPlacement.below => anchor.bottom + gap,
        PopoverPlacement.above => null,
        PopoverPlacement.right => (anchor.center.dy - maxHeight / 2)
            .clamp(edge, screenSize.height - maxHeight - edge)
            .toDouble(),
      };

  /// Distance from the screen bottom to the panel bottom; only set above.
  double? get bottom => placement == PopoverPlacement.above
      ? screenSize.height - anchor.top + gap
      : null;

  /// Origin of the enter/exit scale: the side facing the anchor.
  Alignment get scaleAlignment => switch (placement) {
        PopoverPlacement.below => Alignment.topCenter,
        PopoverPlacement.above => Alignment.bottomCenter,
        PopoverPlacement.right => Alignment.centerLeft,
      };
}
