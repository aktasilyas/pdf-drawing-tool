import 'package:flutter/material.dart';

/// Brightness-aware surface roles for editor chrome.
///
/// Widgets read a role instead of branching on brightness, so the dark/light
/// mapping lives in one place and can move to a ThemeExtension later.
extension ChromeRoles on ColorScheme {
  bool get _isDarkScheme => brightness == Brightness.dark;

  /// Floating pill/toolbar background (pen box, quick colors, sidebar cells).
  Color get floatingSurface => _isDarkScheme ? surfaceContainer : surface;

  /// Docked panel / navigator background.
  Color get panelSurface => _isDarkScheme ? surfaceContainerLow : surface;

  /// Page sidebar background.
  Color get sidebarSurface =>
      _isDarkScheme ? surfaceContainerLow : surfaceContainerLowest;

  /// Editor screen background behind the canvas.
  Color get screenSurface => _isDarkScheme ? surfaceContainerHigh : surface;

  /// Chip / unselected control background inside panels.
  Color get controlSurface =>
      _isDarkScheme ? surfaceContainerHigh : surfaceContainerHighest;

  /// Preview/field background inside settings panels.
  Color get fieldSurface =>
      _isDarkScheme ? surfaceContainerHigh : surfaceContainerLowest;

  /// Color picker popup background.
  Color get pickerSurface => _isDarkScheme ? surfaceContainerHighest : surface;

  /// Hairline border for floating elements; shadow carries elevation in light.
  Border? get floatingBorder =>
      _isDarkScheme ? Border.all(color: outlineVariant) : null;

  /// Alpha for floating element shadows.
  double get floatingShadowAlpha => _isDarkScheme ? 0.3 : 0.1;

  /// Alpha for the pen box shadow.
  double get penBoxShadowAlpha => _isDarkScheme ? 0.4 : 0.07;

  /// Alpha for tinted selected-state fills.
  double get tintAlpha => _isDarkScheme ? 0.2 : 0.1;
}

/// Roles for pen box slots, thumbnails and other small chrome details.
extension ChromeDetailRoles on ColorScheme {
  bool get _isDarkScheme => brightness == Brightness.dark;

  /// Muted fill for inactive slots and hidden-tool rows.
  Color get mutedControlSurface => _isDarkScheme
      ? surfaceContainerHigh.withValues(alpha: 0.5)
      : surfaceContainerHighest;

  /// Fill for color chips in the unified picker.
  Color get chipSurface =>
      _isDarkScheme ? surfaceContainerHighest : surfaceContainerHigh;

  /// Fill for the toolbar group in the page sidebar.
  Color get sidebarGroupSurface => _isDarkScheme
      ? surfaceContainerHighest
      : surfaceContainerHigh.withValues(alpha: 0.5);

  /// Soft outline for floating panels (dark only; light relies on shadow).
  Border? get outlinedFloatingBorder =>
      _isDarkScheme ? Border.all(color: outline.withValues(alpha: 0.2)) : null;

  double get slotSelectedAlpha => _isDarkScheme ? 0.4 : 0.5;
  double get slotIdleAlpha => _isDarkScheme ? 0.2 : 0.3;
  double get slotGlowAlpha => _isDarkScheme ? 0.1 : 0.15;
  double get thumbnailBorderAlpha => _isDarkScheme ? 0.5 : 0.3;

  /// Stroke preview ink, darkened on dark surfaces for contrast.
  Color previewInk(Color c) {
    if (!_isDarkScheme) return c;
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}
