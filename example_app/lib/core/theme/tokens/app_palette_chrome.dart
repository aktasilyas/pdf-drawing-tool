/// Bridges [AppPalette] to the editor chrome palette in drawing_ui
/// (docs/specs/52-editor-chrome.md, D1).
library;

import 'package:drawing_ui/drawing_ui.dart' show ChromePalette;

import 'app_palette.dart';

extension AppPaletteChrome on AppPalette {
  /// The same roles as a [ChromePalette] for drawing_ui widgets.
  ChromePalette get chrome => ChromePalette(
        background: background,
        surface: surface,
        surfaceElevated: surfaceElevated,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
        textDisabled: textDisabled,
        accent: accent,
        accentContainer: accentContainer,
        onAccent: onAccent,
        danger: danger,
        paper: paper,
      );
}
