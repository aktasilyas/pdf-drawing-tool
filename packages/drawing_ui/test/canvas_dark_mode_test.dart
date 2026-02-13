import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/canvas_dark_mode_provider.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_painters.dart';
import 'package:drawing_ui/src/canvas/infinite_background_painter.dart';

void main() {
  group('Canvas Dark Mode Provider', () {
    test('should_return_light_scheme_when_default_mode_off', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final scheme = container.read(canvasColorSchemeProvider);

      expect(scheme.background, equals(const Color(0xFFFFFFFF)));
      expect(scheme.patternLine, equals(const Color(0xFFE0E0E0)));
    });

    test('should_return_dark_scheme_when_mode_on', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      // Set mode to on
      container.read(canvasDarkModeProvider.notifier).setMode(CanvasDarkMode.on);

      final scheme = container.read(canvasColorSchemeProvider);

      expect(scheme.background, equals(const Color(0xFF2C2C2C)));
      expect(scheme.patternLine, equals(const Color(0xFF4A4A4A)));
    });

    test('should_return_dark_scheme_when_followSystem_and_dark_brightness', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(null),
          platformBrightnessProvider.overrideWith((ref) => Brightness.dark),
        ],
      );
      addTearDown(container.dispose);

      // Set mode to followSystem
      container.read(canvasDarkModeProvider.notifier).setMode(CanvasDarkMode.followSystem);

      final scheme = container.read(canvasColorSchemeProvider);

      expect(scheme.background, equals(const Color(0xFF2C2C2C)));
      expect(scheme.patternLine, equals(const Color(0xFF4A4A4A)));
    });

    test('should_return_light_scheme_when_followSystem_and_light_brightness', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(null),
          platformBrightnessProvider.overrideWith((ref) => Brightness.light),
        ],
      );
      addTearDown(container.dispose);

      // Set mode to followSystem
      container.read(canvasDarkModeProvider.notifier).setMode(CanvasDarkMode.followSystem);

      final scheme = container.read(canvasColorSchemeProvider);

      expect(scheme.background, equals(const Color(0xFFFFFFFF)));
      expect(scheme.patternLine, equals(const Color(0xFFE0E0E0)));
    });
  });

  group('CanvasColorScheme', () {
    test('should_override_default_white_in_dark_mode', () {
      final darkScheme = CanvasColorScheme.dark();

      // effectiveBackground should replace default white with dark background
      final effectiveColor = darkScheme.effectiveBackground(0xFFFFFFFF);

      expect(effectiveColor, equals(const Color(0xFF2C2C2C)));
    });

    test('should_preserve_custom_color_in_dark_mode', () {
      final darkScheme = CanvasColorScheme.dark();

      // Custom red color should be preserved, not overridden
      final effectiveColor = darkScheme.effectiveBackground(0xFFFF0000);

      expect(effectiveColor, equals(const Color(0xFFFF0000)));
    });

    test('should_have_warm_tones_in_sepia_mode', () {
      final sepiaScheme = CanvasColorScheme.sepia();

      // Sepia background should be warm-toned (not pure white or gray)
      expect(sepiaScheme.background, equals(const Color(0xFFF5F0E8)));
      expect(sepiaScheme.patternLine, equals(const Color(0xFFD5C9B5)));
      expect(sepiaScheme.marginLine, equals(const Color(0xFFBF7B5E)));
    });
  });

  group('Painters with ColorScheme', () {
    test('should_accept_colorScheme_in_DynamicBackgroundPainter', () {
      final colorScheme = CanvasColorScheme.dark();
      final background = const PageBackground(
        type: BackgroundType.blank,
        color: 0xFFFFFFFF,
      );

      final painter = DynamicBackgroundPainter(
        background: background,
        colorScheme: colorScheme,
      );

      expect(painter.colorScheme, equals(colorScheme));
      expect(painter.background, equals(background));
    });

    test('should_accept_colorScheme_in_InfiniteBackgroundPainter', () {
      final colorScheme = CanvasColorScheme.sepia();
      final background = const PageBackground(
        type: BackgroundType.grid,
        color: 0xFFFFFFFF,
        gridSpacing: 25.0,
      );

      final painter = InfiniteBackgroundPainter(
        background: background,
        zoom: 1.0,
        offset: Offset.zero,
        colorScheme: colorScheme,
      );

      expect(painter.colorScheme, equals(colorScheme));
      expect(painter.background, equals(background));
      expect(painter.zoom, equals(1.0));
      expect(painter.offset, equals(Offset.zero));
    });

    test('should_work_with_null_colorScheme_in_painters', () {
      final background = const PageBackground(
        type: BackgroundType.lined,
        color: 0xFFFFFFFF,
        lineSpacing: 25.0,
      );

      // DynamicBackgroundPainter with null colorScheme
      final dynamicPainter = DynamicBackgroundPainter(
        background: background,
        colorScheme: null,
      );

      expect(dynamicPainter.colorScheme, isNull);

      // InfiniteBackgroundPainter with null colorScheme
      final infinitePainter = InfiniteBackgroundPainter(
        background: background,
        colorScheme: null,
      );

      expect(infinitePainter.colorScheme, isNull);
    });
  });
}
