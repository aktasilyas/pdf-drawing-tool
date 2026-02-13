import 'package:flutter/material.dart';

/// Default page background colors from PageBackground model.
const int _defaultWhite = 0xFFFFFFFF;
const int _defaultLineColor = 0xFFE0E0E0;
const int _defaultDotColor = 0xFFCCCCCC;

/// Color scheme for canvas rendering in different theme modes.
///
/// Controls background, pattern lines, dots, and other canvas visual elements.
/// Does NOT affect user-drawn stroke colors — those are preserved as-is.
class CanvasColorScheme {
  const CanvasColorScheme({
    required this.background,
    required this.patternLine,
    required this.patternDot,
    required this.rulerMark,
    required this.selectionHighlight,
    required this.marginLine,
  });

  /// Canvas background color (replaces PageBackground.color at render time).
  final Color background;

  /// Grid and line pattern color.
  final Color patternLine;

  /// Dot pattern color.
  final Color patternDot;

  /// Ruler marks and margin lines.
  final Color rulerMark;

  /// Selection/lasso highlight overlay.
  final Color selectionHighlight;

  /// Special margin lines (Cornell notes, legal pad etc.)
  final Color marginLine;

  /// Light theme — default white paper.
  factory CanvasColorScheme.light() => const CanvasColorScheme(
        background: Color(0xFFFFFFFF),
        patternLine: Color(0xFFE0E0E0),
        patternDot: Color(0xFFD0D0D0),
        rulerMark: Color(0xFFBDBDBD),
        selectionHighlight: Color(0x332196F3),
        marginLine: Color(0xFFE57373),
      );

  /// Dark theme — dark gray paper.
  factory CanvasColorScheme.dark() => const CanvasColorScheme(
        background: Color(0xFF2C2C2C),
        patternLine: Color(0xFF4A4A4A),
        patternDot: Color(0xFF505050),
        rulerMark: Color(0xFF5A5A5A),
        selectionHighlight: Color(0x3364B5F6),
        marginLine: Color(0xFFEF9A9A),
      );

  /// Sepia/warm theme — optional future addition.
  factory CanvasColorScheme.sepia() => const CanvasColorScheme(
        background: Color(0xFFF5F0E8),
        patternLine: Color(0xFFD5C9B5),
        patternDot: Color(0xFFCBC0AC),
        rulerMark: Color(0xFFC0B49E),
        selectionHighlight: Color(0x338D6E63),
        marginLine: Color(0xFFBF7B5E),
      );

  /// Returns the effective background color for a given PageBackground.
  ///
  /// If the page uses the default white color, returns the scheme's background.
  /// Otherwise the user set a custom color — respect it (don't override).
  Color effectiveBackground(int pageBackgroundColor) {
    if (pageBackgroundColor == _defaultWhite) {
      return background;
    }
    return Color(pageBackgroundColor);
  }

  /// Returns the effective line color for grid/lined patterns.
  ///
  /// If the page uses a default line color (or null), returns the scheme's
  /// patternLine. Otherwise the user set a custom color — respect it.
  Color effectiveLineColor(int? pageLineColor) {
    if (pageLineColor == null || pageLineColor == _defaultLineColor) {
      return patternLine;
    }
    return Color(pageLineColor);
  }

  /// Returns the effective dot color for dotted patterns.
  ///
  /// Handles the dotted background default (0xFFCCCCCC) as well as the
  /// common grid default (0xFFE0E0E0) and null.
  Color effectiveDotColor(int? pageLineColor) {
    if (pageLineColor == null ||
        pageLineColor == _defaultLineColor ||
        pageLineColor == _defaultDotColor) {
      return patternDot;
    }
    return Color(pageLineColor);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasColorScheme &&
          background == other.background &&
          patternLine == other.patternLine &&
          patternDot == other.patternDot &&
          rulerMark == other.rulerMark &&
          selectionHighlight == other.selectionHighlight &&
          marginLine == other.marginLine;

  @override
  int get hashCode => Object.hash(
        background,
        patternLine,
        patternDot,
        rulerMark,
        selectionHighlight,
        marginLine,
      );
}
