import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';

/// Theme for chrome goldens: the brief palette registered the way
/// example_app registers it, so goldens render the shipped colours.
ThemeData chromeTheme(Brightness brightness) {
  final palette =
      brightness == Brightness.dark ? ChromePalette.dark : ChromePalette.light;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      surface: palette.surface,
      primary: palette.accent,
      error: palette.danger,
    ),
    scaffoldBackgroundColor: palette.background,
    extensions: [palette],
  );
}
