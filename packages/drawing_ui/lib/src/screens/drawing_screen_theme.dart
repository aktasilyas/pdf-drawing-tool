import 'package:drawing_ui/src/theme/theme.dart';

/// Builds the editor's [DrawingTheme] from the chrome palette
/// (docs/specs/52-editor-chrome.md, section 4).
///
/// The toolbar band is the desk `background`, idle icons are `textMuted`,
/// and ink blue (`accent`) is kept for selection only.
DrawingTheme drawingThemeFromChrome(ChromePalette palette) {
  return DrawingTheme(
    toolbarBackground: palette.background,
    toolbarIconColor: palette.textMuted,
    toolbarIconSelectedColor: palette.accent,
    toolbarIconDisabledColor: palette.textDisabled,
    panelBackground: palette.surfaceElevated,
    panelBorderColor: palette.border,
    penBoxBackground: palette.surface,
    penBoxSlotSelectedColor: palette.accentContainer,
  );
}
