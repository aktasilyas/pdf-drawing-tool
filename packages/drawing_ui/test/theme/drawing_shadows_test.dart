import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every shadow helper for both brightnesses, for the "neutral only" check.
List<BoxShadow> _all() => [
      for (final b in Brightness.values) ...[
        ...DrawingShadows.chrome(b),
        ...DrawingShadows.panel(b),
        ...DrawingShadows.floating(b),
        ...DrawingShadows.toolbar(b),
        ...DrawingShadows.page(b),
        ...DrawingShadows.selection(b),
      ],
    ];

void main() {
  test('all shadows are neutral black (no emerald tint)', () {
    for (final s in _all()) {
      expect(s.color.r, 0, reason: '$s');
      expect(s.color.g, 0, reason: '$s');
      expect(s.color.b, 0, reason: '$s');
    }
  });

  test('chrome: two soft layers in light, none in dark (spec 52 s5)', () {
    final light = DrawingShadows.chrome(Brightness.light);
    expect(light, hasLength(2));
    expect(light[0].color.a, closeTo(0.06, 0.005));
    expect(light[0].offset, const Offset(0, 1));
    expect(light[0].blurRadius, 3);
    expect(light[1].color.a, closeTo(0.04, 0.005));
    expect(light[1].offset, const Offset(0, 4));
    expect(light[1].blurRadius, 12);
    expect(light[1].spreadRadius, -2);
    expect(DrawingShadows.chrome(Brightness.dark), isEmpty);
  });

  test('panel matches spec 52 s5 in light and dark', () {
    final light = DrawingShadows.panel(Brightness.light);
    expect(light, hasLength(2));
    expect(light[0].color.a, closeTo(0.08, 0.005));
    expect(light[0].offset, const Offset(0, 8));
    expect(light[0].blurRadius, 24);
    expect(light[0].spreadRadius, -4);
    expect(light[1].color.a, closeTo(0.04, 0.005));
    expect(light[1].offset, const Offset(0, 1));
    expect(light[1].blurRadius, 3);

    final dark = DrawingShadows.panel(Brightness.dark);
    expect(dark, hasLength(1));
    expect(dark[0].color.a, closeTo(0.32, 0.005));
    expect(dark[0].offset, const Offset(0, 8));
    expect(dark[0].blurRadius, 24);
    expect(dark[0].spreadRadius, -4);
  });

  test('selection keeps an explicit tint colour', () {
    const tint = Color(0xFF3355FF);
    final s = DrawingShadows.selection(Brightness.light, tint).single;
    expect(s.color.b, closeTo(1, 0.001));
  });
}
