import 'package:flutter/material.dart';

/// Brightness-aware surface roles for editor chrome.
///
/// Widgets read a role instead of branching on brightness, so the dark/light
/// mapping lives in one place and can move to a ThemeExtension later.
extension ChromeRoles on ColorScheme {
  bool get _dark => brightness == Brightness.dark;

  /// Floating pill/toolbar background (pen box, quick colors, sidebar cells).
  Color get floatingSurface => _dark ? surfaceContainer : surface;

  /// Docked panel / navigator background.
  Color get panelSurface => _dark ? surfaceContainerLow : surface;

  /// Page sidebar background.
  Color get sidebarSurface =>
      _dark ? surfaceContainerLow : surfaceContainerLowest;

  /// Editor screen background behind the canvas.
  Color get screenSurface => _dark ? surfaceContainerHigh : surface;

  /// Chip / unselected control background inside panels.
  Color get controlSurface =>
      _dark ? surfaceContainerHigh : surfaceContainerHighest;

  /// Preview/field background inside settings panels.
  Color get fieldSurface =>
      _dark ? surfaceContainerHigh : surfaceContainerLowest;

  /// Color picker popup background.
  Color get pickerSurface => _dark ? surfaceContainerHighest : surface;

  /// Hairline border for floating elements; shadow carries elevation in light.
  Border? get floatingBorder =>
      _dark ? Border.all(color: outlineVariant) : null;

  /// Alpha for floating element shadows.
  double get floatingShadowAlpha => _dark ? 0.3 : 0.1;

  /// Alpha for the pen box shadow.
  double get penBoxShadowAlpha => _dark ? 0.4 : 0.07;

  /// Alpha for tinted selected-state fills.
  double get tintAlpha => _dark ? 0.2 : 0.1;
}
