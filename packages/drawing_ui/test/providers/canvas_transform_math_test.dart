import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drawing_ui/src/providers/canvas_transform_math.dart';

void main() {
  const viewport = Size(800, 1000);
  const page = Size(400, 500);

  group('fitPageZoom', () {
    test('uses fit-height when height is the tight axis', () {
      expect(fitPageZoom(const Size(1000, 500), page), 1.0);
    });

    test('pads fit-width when width is the tight axis', () {
      expect(fitPageZoom(const Size(400, 1000), page), closeTo(0.96, 1e-9));
    });
  });

  test('centeredPageOffset centers both axes', () {
    expect(centeredPageOffset(viewport, page, 1.0), const Offset(200, 250));
  });

  group('clampPageOffset', () {
    test('centers an axis where the page is smaller than the viewport', () {
      final result = clampPageOffset(
        const Offset(-50, -60),
        viewportSize: viewport,
        pageSize: page,
        zoom: 1.0,
      );
      expect(result, const Offset(200, 250));
    });

    test('clamps an axis where the page is larger than the viewport', () {
      // At zoom 4 the page is 1600 x 2000: range [-800, 0] x [-1000, 0].
      final tooFar = clampPageOffset(
        const Offset(-5000, 300),
        viewportSize: viewport,
        pageSize: page,
        zoom: 4.0,
      );
      expect(tooFar, const Offset(-800, 0));

      final inside = clampPageOffset(
        const Offset(-100, -200),
        viewportSize: viewport,
        pageSize: page,
        zoom: 4.0,
      );
      expect(inside, const Offset(-100, -200));
    });
  });
}
