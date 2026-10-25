import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/theme/chrome_roles.dart';

void main() {
  final light = ColorScheme.fromSeed(seedColor: Colors.indigo);
  final dark = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );

  group('light', () {
    test('surfaces', () {
      expect(light.floatingSurface, light.surface);
      expect(light.panelSurface, light.surface);
      expect(light.sidebarSurface, light.surfaceContainerLowest);
      expect(light.screenSurface, light.surface);
      expect(light.controlSurface, light.surfaceContainerHighest);
      expect(light.fieldSurface, light.surfaceContainerLowest);
      expect(light.pickerSurface, light.surface);
      expect(light.chipSurface, light.surfaceContainerHigh);
      expect(light.mutedControlSurface, light.surfaceContainerHighest);
    });

    test('borders, alphas and ink', () {
      expect(light.floatingBorder, isNull);
      expect(light.outlinedFloatingBorder, isNull);
      expect(light.floatingShadowAlpha, 0.1);
      expect(light.penBoxShadowAlpha, 0.07);
      expect(light.tintAlpha, 0.1);
      expect(light.slotSelectedAlpha, 0.5);
      expect(light.thumbnailBorderAlpha, 0.3);
      expect(light.previewInk(Colors.red), Colors.red);
    });
  });

  group('dark', () {
    test('surfaces', () {
      expect(dark.floatingSurface, dark.surfaceContainer);
      expect(dark.panelSurface, dark.surfaceContainerLow);
      expect(dark.sidebarSurface, dark.surfaceContainerLow);
      expect(dark.screenSurface, dark.surfaceContainerHigh);
      expect(dark.controlSurface, dark.surfaceContainerHigh);
      expect(dark.fieldSurface, dark.surfaceContainerHigh);
      expect(dark.pickerSurface, dark.surfaceContainerHighest);
      expect(dark.chipSurface, dark.surfaceContainerHighest);
    });

    test('borders, alphas and ink', () {
      expect(dark.floatingBorder, isNotNull);
      expect(dark.outlinedFloatingBorder, isNotNull);
      expect(dark.floatingShadowAlpha, 0.3);
      expect(dark.penBoxShadowAlpha, 0.4);
      expect(dark.tintAlpha, 0.2);
      expect(dark.slotSelectedAlpha, 0.4);
      expect(dark.thumbnailBorderAlpha, 0.5);
      expect(dark.previewInk(Colors.red), isNot(Colors.red));
    });
  });
}
