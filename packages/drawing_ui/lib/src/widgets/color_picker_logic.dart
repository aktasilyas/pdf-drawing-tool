import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show HSVColor;

/// Pure colour maths behind `CompactColorPicker`: no widgets, no state.
abstract final class ColorPickerLogic {
  /// Number of recent-colour slots shown under the picker.
  static const int recentSlotCount = 5;

  /// Lowest opacity a picked colour keeps, so it never becomes invisible.
  static const double minOpacity = 0.01;

  /// 8-bit red, green and blue channels of [color].
  static ({int r, int g, int b}) rgb(Color color) => (
        r: _channel(color.r),
        g: _channel(color.g),
        b: _channel(color.b),
      );

  /// Upper-case `RRGGBB` hex of [color], alpha ignored.
  static String hex(Color color) {
    final c = rgb(color);
    return [c.r, c.g, c.b]
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  /// The colour the picker currently represents: [hsv] with [opacity], or
  /// fully opaque when the picker hides the opacity slider.
  static Color compose(
    HSVColor hsv,
    double opacity, {
    required bool showOpacity,
  }) =>
      hsv.toColor().withValues(alpha: showOpacity ? opacity : 1.0);

  /// Opacity to adopt when [color] is picked from a swatch or recent slot.
  static double opacityOf(Color color) => color.a.clamp(minOpacity, 1.0);

  /// [recent] (newest first) padded with `null` to [count] slots.
  static List<Color?> recentSlots(
    List<Color> recent, {
    int count = recentSlotCount,
  }) =>
      List<Color?>.generate(count, (i) => i < recent.length ? recent[i] : null);

  static int _channel(double v) => (v * 255).round().clamp(0, 255);
}
