import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden/helpers/chrome_theme.dart';

void main() {
  group('ChromePalette defaults match docs/design/BRIEF.md', () {
    test('light', () {
      const p = ChromePalette.light;
      expect(p.background, const Color(0xFFF4F1EA));
      expect(p.surface, const Color(0xFFFBF9F4));
      expect(p.surfaceElevated, const Color(0xFFFFFFFF));
      expect(p.border, const Color(0xFFE4DED2));
      expect(p.textPrimary, const Color(0xFF22201C));
      expect(p.textMuted, const Color(0xFF6E685E));
      expect(p.textDisabled, const Color(0xFFA8A296));
      expect(p.accent, const Color(0xFF2B4C7E));
      expect(p.accentContainer, const Color(0xFFDCE5F2));
      expect(p.onAccent, const Color(0xFFFFFFFF));
      expect(p.danger, const Color(0xFFB3261E));
      expect(p.paper, const Color(0xFFFFFDF8));
    });

    test('dark keeps paper light', () {
      const p = ChromePalette.dark;
      expect(p.background, const Color(0xFF1B1A18));
      expect(p.surface, const Color(0xFF242320));
      expect(p.surfaceElevated, const Color(0xFF2D2B28));
      expect(p.border, const Color(0xFF3A3834));
      expect(p.textPrimary, const Color(0xFFECE8E0));
      expect(p.textMuted, const Color(0xFFA39D92));
      expect(p.textDisabled, const Color(0xFF6B665E));
      expect(p.accent, const Color(0xFF8FAEDB));
      expect(p.accentContainer, const Color(0xFF263548));
      expect(p.onAccent, const Color(0xFF14233A));
      expect(p.danger, const Color(0xFFF2B8B5));
      expect(p.paper, const Color(0xFFF3EFE6));
    });
  });

  test('fromColorScheme maps scheme roles', () {
    final s = ColorScheme.fromSeed(seedColor: Colors.indigo);
    final p = ChromePalette.fromColorScheme(s);
    expect(p.background, s.surfaceContainerLow);
    expect(p.surface, s.surface);
    expect(p.surfaceElevated, s.surfaceBright);
    expect(p.border, s.outlineVariant);
    expect(p.textPrimary, s.onSurface);
    expect(p.textMuted, s.onSurfaceVariant);
    expect(p.textDisabled, s.onSurface.withValues(alpha: 0.38));
    expect(p.accent, s.primary);
    expect(p.accentContainer, s.primaryContainer);
    expect(p.onAccent, s.onPrimary);
    expect(p.danger, s.error);
    expect(p.paper, ChromePalette.light.paper);
  });

  test('copyWith replaces only given roles', () {
    final p = ChromePalette.light.copyWith(accent: Colors.red);
    expect(p.accent, Colors.red);
    expect(p.surface, ChromePalette.light.surface);
    expect(p.paper, ChromePalette.light.paper);
  });

  test('lerp interpolates every role and ignores foreign types', () {
    const a = ChromePalette.light;
    const b = ChromePalette.dark;
    expect(a.lerp(b, 0), a);
    expect(a.lerp(b, 1), b);
    final mid = a.lerp(b, 0.5);
    expect(mid.surface, Color.lerp(a.surface, b.surface, 0.5));
    expect(mid.paper, Color.lerp(a.paper, b.paper, 0.5));
    expect(a.lerp(null, 0.5), a);
  });

  test('equality is by value', () {
    expect(ChromePalette.light.copyWith(), ChromePalette.light);
    expect(
        ChromePalette.light.copyWith().hashCode, ChromePalette.light.hashCode);
    expect(ChromePalette.light == ChromePalette.dark, isFalse);
  });

  group('ChromePalette.of', () {
    Future<ChromePalette> resolve(WidgetTester tester, ThemeData theme) async {
      late ChromePalette result;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(builder: (context) {
          result = ChromePalette.of(context);
          return const SizedBox();
        }),
      ));
      return result;
    }

    testWidgets('returns the registered extension', (tester) async {
      expect(await resolve(tester, chromeTheme(Brightness.dark)),
          ChromePalette.dark);
      expect(await resolve(tester, chromeTheme(Brightness.light)),
          ChromePalette.light);
    });

    testWidgets('falls back to the color scheme', (tester) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      );
      expect(
        await resolve(tester, theme),
        ChromePalette.fromColorScheme(theme.colorScheme),
      );
    });
  });
}
