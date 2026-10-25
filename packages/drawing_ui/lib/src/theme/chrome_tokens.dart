/// Spacing, radius, motion and size tokens for editor chrome
/// (docs/specs/52-editor-chrome.md, D2).
///
/// `drawing_ui` cannot import `example_app`, so these mirror `AppSpacing` /
/// `AppRadius` on the same 4dp grid. Widgets use these instead of literals.
library;

/// Spacing scale (4dp grid; [xxs] only for hairline gaps such as focus rings).
abstract final class ChromeSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii. Nested shapes stay concentric (capsule xl, button md).
abstract final class ChromeRadius {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double full = 999;
}

/// Motion durations (spec section 7).
abstract final class ChromeDurations {
  /// Pressed fade, popover exit, reader-mode fade.
  static const Duration instant = Duration(milliseconds: 100);

  /// Tool selection, popover enter.
  static const Duration fast = Duration(milliseconds: 200);

  /// Sidebar and phone drawer.
  static const Duration normal = Duration(milliseconds: 300);
}

/// Icon sizes: [lg] in toolbars, [md] in panels, [sm] for inline glyphs.
abstract final class ChromeIconSizes {
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
}

/// Fixed chrome dimensions.
abstract final class ChromeSizes {
  /// Minimum hit area for any tappable chrome control.
  static const double minTouchTarget = 48;
}
