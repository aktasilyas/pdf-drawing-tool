import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/theme.dart';

/// Floating rounded container that groups editor chrome controls
/// (docs/specs/52-editor-chrome.md, section 4).
///
/// Fill `surface`, 1dp `border`, radius [ChromeRadius.xl], `chrome` shadow,
/// [height] 52. Children are laid out in a minimum-size [Row].
class ChromeCapsule extends StatelessWidget {
  const ChromeCapsule({super.key, required this.children});

  /// Outer height of every capsule, border included.
  static const double height = 52;

  /// Border width.
  static const double borderWidth = 1;

  /// Horizontal space taken by padding and border, excluding children.
  static const double horizontalInset = 2 * (ChromeSpacing.xs + borderWidth);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final brightness = Theme.of(context).brightness;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.xs),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(ChromeRadius.xl),
        border: Border.all(color: palette.border, width: borderWidth),
        boxShadow: DrawingShadows.chrome(brightness),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Thin vertical separator between control groups inside a [ChromeCapsule].
class ChromeDivider extends StatelessWidget {
  const ChromeDivider({super.key});

  /// Line thickness.
  static const double thickness = 1;

  /// Line length.
  static const double length = 24;

  /// Horizontal space the divider takes in total.
  static const double extent = thickness + 2 * ChromeSpacing.xs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: thickness,
      height: length,
      margin: const EdgeInsets.symmetric(horizontal: ChromeSpacing.xs),
      color: ChromePalette.of(context).border,
    );
  }
}
