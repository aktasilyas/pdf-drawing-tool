import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/screens/drawing_screen_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final palette in [ChromePalette.light, ChromePalette.dark]) {
    final name = palette == ChromePalette.light ? 'light' : 'dark';

    test('maps chrome roles onto the drawing theme ($name)', () {
      final theme = drawingThemeFromChrome(palette);

      expect(theme.toolbarBackground, palette.background);
      expect(theme.toolbarIconColor, palette.textMuted);
      expect(theme.toolbarIconSelectedColor, palette.accent);
      expect(theme.toolbarIconDisabledColor, palette.textDisabled);
      expect(theme.panelBackground, palette.surfaceElevated);
      expect(theme.panelBorderColor, palette.border);
      expect(theme.penBoxBackground, palette.surface);
      expect(theme.penBoxSlotSelectedColor, palette.accentContainer);
    });

    test('keeps ink blue off the toolbar band ($name)', () {
      final theme = drawingThemeFromChrome(palette);

      expect(theme.toolbarBackground, isNot(palette.accent));
      expect(theme.toolbarIconColor, isNot(palette.accent));
    });
  }
}
