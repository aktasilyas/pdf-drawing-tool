import 'package:flutter/material.dart';

import 'drawing_colors.dart';

/// Theme configuration for drawing UI components.
///
/// Use [DrawingTheme.of] to access the theme in the widget tree,
/// or wrap your app with [DrawingThemeProvider] to customize.
class DrawingTheme {
  const DrawingTheme({
    this.toolbarHeight = 56.0,
    this.penBoxWidth = 64.0,
    this.panelMaxWidth = 300.0,
    this.panelBorderRadius = 16.0,
    this.toolButtonSize = 38.0,
    this.toolIconSize = 20.0,
    this.penSlotSize = 48.0,
    this.colorChipSize = 32.0,
    this.sliderTrackHeight = 4.0,
    this.toolbarBackground = DrawingColors.toolbarBackground,
    this.toolbarIconColor = DrawingColors.toolbarIcon,
    this.toolbarIconSelectedColor = DrawingColors.toolbarIconSelected,
    this.toolbarIconDisabledColor = DrawingColors.toolbarIconDisabled,
    this.penBoxBackground = DrawingColors.penBoxBackground,
    this.penBoxSlotSelectedColor = DrawingColors.penBoxSlotSelected,
    this.panelBackground = const Color(0xFFFFFFFF),
    this.panelBorderColor = DrawingColors.panelBorder,
    this.canvasBackground = DrawingColors.canvasBackground,
    this.penColors = DrawingColors.penColors,
    this.highlighterColors = DrawingColors.highlighterColors,
    this.panelElevation = 20.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
  });

  /// Height of the top toolbar.
  final double toolbarHeight;

  /// Width of the left pen box sidebar.
  final double penBoxWidth;

  /// Maximum width of tool settings panels.
  final double panelMaxWidth;

  /// Border radius for panels and overlays.
  final double panelBorderRadius;

  /// Size of tool buttons in the toolbar.
  final double toolButtonSize;

  /// Size of icons within tool buttons.
  final double toolIconSize;

  /// Size of pen preset slots in the pen box.
  final double penSlotSize;

  /// Size of color chip buttons.
  final double colorChipSize;

  /// Height of slider tracks.
  final double sliderTrackHeight;

  /// Background color of the toolbar.
  final Color toolbarBackground;

  /// Color of toolbar icons in default state.
  final Color toolbarIconColor;

  /// Color of toolbar icons when selected.
  final Color toolbarIconSelectedColor;

  /// Color of toolbar icons when disabled.
  final Color toolbarIconDisabledColor;

  /// Background color of the pen box.
  final Color penBoxBackground;

  /// Background color of selected pen slot.
  final Color penBoxSlotSelectedColor;

  /// Background color of panels.
  final Color panelBackground;

  /// Border color of panels.
  final Color panelBorderColor;

  /// Background color of the canvas.
  final Color canvasBackground;

  /// Available pen colors for selection.
  final List<Color> penColors;

  /// Available highlighter colors for selection.
  final List<Color> highlighterColors;

  /// Elevation of floating panels.
  final double panelElevation;

  /// Duration for UI animations.
  final Duration animationDuration;

  /// Curve for UI animations.
  final Curve animationCurve;

  /// Default theme instance.
  static const DrawingTheme defaultTheme = DrawingTheme();

  /// Gets the [DrawingTheme] from the widget tree.
  ///
  /// Returns [defaultTheme] if no [DrawingThemeProvider] is found.
  static DrawingTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<DrawingThemeProvider>();
    return provider?.theme ?? defaultTheme;
  }

  /// Creates a copy of this theme with the given overrides.
  DrawingTheme copyWith({
    double? toolbarHeight,
    double? penBoxWidth,
    double? panelMaxWidth,
    double? panelBorderRadius,
    double? toolButtonSize,
    double? toolIconSize,
    double? penSlotSize,
    double? colorChipSize,
    double? sliderTrackHeight,
    Color? toolbarBackground,
    Color? toolbarIconColor,
    Color? toolbarIconSelectedColor,
    Color? toolbarIconDisabledColor,
    Color? penBoxBackground,
    Color? penBoxSlotSelectedColor,
    Color? panelBackground,
    Color? panelBorderColor,
    Color? canvasBackground,
    List<Color>? penColors,
    List<Color>? highlighterColors,
    double? panelElevation,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return DrawingTheme(
      toolbarHeight: toolbarHeight ?? this.toolbarHeight,
      penBoxWidth: penBoxWidth ?? this.penBoxWidth,
      panelMaxWidth: panelMaxWidth ?? this.panelMaxWidth,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      toolButtonSize: toolButtonSize ?? this.toolButtonSize,
      toolIconSize: toolIconSize ?? this.toolIconSize,
      penSlotSize: penSlotSize ?? this.penSlotSize,
      colorChipSize: colorChipSize ?? this.colorChipSize,
      sliderTrackHeight: sliderTrackHeight ?? this.sliderTrackHeight,
      toolbarBackground: toolbarBackground ?? this.toolbarBackground,
      toolbarIconColor: toolbarIconColor ?? this.toolbarIconColor,
      toolbarIconSelectedColor:
          toolbarIconSelectedColor ?? this.toolbarIconSelectedColor,
      toolbarIconDisabledColor:
          toolbarIconDisabledColor ?? this.toolbarIconDisabledColor,
      penBoxBackground: penBoxBackground ?? this.penBoxBackground,
      penBoxSlotSelectedColor:
          penBoxSlotSelectedColor ?? this.penBoxSlotSelectedColor,
      panelBackground: panelBackground ?? this.panelBackground,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      canvasBackground: canvasBackground ?? this.canvasBackground,
      penColors: penColors ?? this.penColors,
      highlighterColors: highlighterColors ?? this.highlighterColors,
      panelElevation: panelElevation ?? this.panelElevation,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }
}

/// Provides [DrawingTheme] to descendant widgets.
class DrawingThemeProvider extends InheritedWidget {
  const DrawingThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  /// The theme to provide.
  final DrawingTheme theme;

  @override
  bool updateShouldNotify(DrawingThemeProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}
