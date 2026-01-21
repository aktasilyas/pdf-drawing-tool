/// Color utility extensions and helpers.
import 'package:flutter/material.dart';

/// Extension methods for Color class.
///
/// Provides safe alternatives to deprecated methods and common color operations.
extension ColorUtils on Color {
  /// Safe withAlpha (alternative to deprecated withOpacity).
  ///
  /// Example:
  /// ```dart
  /// final transparentRed = Colors.red.withAlphaSafe(0.5);
  /// ```
  Color withAlphaSafe(double opacity) {
    return withAlpha((opacity * 255).round().clamp(0, 255));
  }

  /// Compare colors ignoring alpha channel.
  ///
  /// Useful for color matching in pickers and palettes.
  ///
  /// Example:
  /// ```dart
  /// final red1 = Colors.red.withAlpha(128);
  /// final red2 = Colors.red.withAlpha(255);
  /// assert(red1.matchesRGB(red2) == true);
  /// ```
  bool matchesRGB(Color other) {
    return (r * 255).round() == (other.r * 255).round() &&
        (g * 255).round() == (other.g * 255).round() &&
        (b * 255).round() == (other.b * 255).round();
  }

  /// Get RGB components as integers (0-255).
  ///
  /// Returns a record with (r, g, b) values.
  ({int r, int g, int b}) get rgbInt => (
        r: (r * 255).round().clamp(0, 255),
        g: (g * 255).round().clamp(0, 255),
        b: (b * 255).round().clamp(0, 255),
      );

  /// Get alpha component as integer (0-255).
  int get alphaInt => (a * 255).round().clamp(0, 255);
}
