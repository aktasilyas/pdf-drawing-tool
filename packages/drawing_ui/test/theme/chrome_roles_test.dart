import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/theme/chrome_roles.dart';

void main() {
  final light = ColorScheme.fromSeed(seedColor: Colors.indigo);
  final dark = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );

  test('light scheme uses flat surfaces without hairline border', () {
    expect(light.floatingSurface, light.surface);
    expect(light.panelSurface, light.surface);
    expect(light.floatingBorder, isNull);
    expect(light.floatingShadowAlpha, 0.1);
  });

  test('dark scheme uses raised surfaces and hairline border', () {
    expect(dark.floatingSurface, dark.surfaceContainer);
    expect(dark.panelSurface, dark.surfaceContainerLow);
    expect(dark.floatingBorder, isNotNull);
    expect(dark.floatingShadowAlpha, 0.3);
  });
}
