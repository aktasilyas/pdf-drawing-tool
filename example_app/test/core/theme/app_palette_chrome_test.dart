import 'package:drawing_ui/drawing_ui.dart' show ChromePalette;
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';

void main() {
  test('chrome mirrors every AppPalette role', () {
    for (final p in [AppPalette.light, AppPalette.dark]) {
      final c = p.chrome;
      expect(c.background, p.background);
      expect(c.surface, p.surface);
      expect(c.surfaceElevated, p.surfaceElevated);
      expect(c.border, p.border);
      expect(c.textPrimary, p.textPrimary);
      expect(c.textMuted, p.textMuted);
      expect(c.textDisabled, p.textDisabled);
      expect(c.accent, p.accent);
      expect(c.accentContainer, p.accentContainer);
      expect(c.onAccent, p.onAccent);
      expect(c.danger, p.danger);
      expect(c.paper, p.paper);
    }
  });

  test('app themes register the chrome palette', () {
    expect(AppTheme.light.extension<ChromePalette>(), AppPalette.light.chrome);
    expect(AppTheme.dark.extension<ChromePalette>(), AppPalette.dark.chrome);
    expect(AppTheme.light.extension<AppPalette>(), AppPalette.light);
  });

  test('brief palette and drawing_ui defaults stay in sync', () {
    expect(AppPalette.light.chrome, ChromePalette.light);
    expect(AppPalette.dark.chrome, ChromePalette.dark);
  });
}
