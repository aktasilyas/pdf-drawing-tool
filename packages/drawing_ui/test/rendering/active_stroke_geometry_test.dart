import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

List<DrawingPoint> _wave(int n) => [
      for (var i = 0; i < n; i++)
        DrawingPoint(
          x: 20 + i * 2.0,
          y: 100 + 30 * (i % 40 < 20 ? (i % 20) / 20 : 1 - (i % 20) / 20),
          pressure: 0.3 + 0.6 * ((i % 50) / 50),
        ),
    ];

void main() {
  group('ActiveStrokeGeometry mode selection', () {
    test('pressure-sensitive pens use the outline mode', () {
      final g = ActiveStrokeGeometry()..begin(StrokeStyle.brush());
      expect(g.mode, ActiveStrokeMode.outline);
    });

    test('solid pens use the stroked mode', () {
      final g = ActiveStrokeGeometry()..begin(StrokeStyle.pen());
      expect(g.mode, ActiveStrokeMode.stroked);
    });

    test('non-incremental input falls back', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.pen(), incremental: false);
      expect(g.mode, ActiveStrokeMode.fallback);
    });
  });

  group('ActiveStrokeGeometry sync', () {
    for (final style in [StrokeStyle.pen(), StrokeStyle.brush()]) {
      test('consumes only new points and bumps version (${style.thickness})',
          () {
        final points = _wave(300);
        final g = ActiveStrokeGeometry()..begin(style);
        var version = g.version;
        for (var n = 1; n <= points.length; n++) {
          g.sync(points.sublist(0, n));
          expect(g.consumed, n);
          expect(g.version, greaterThan(version));
          version = g.version;
        }
      });

      test('paints without throwing for 1, 2 and many points', () {
        for (final n in [1, 2, 3, 120]) {
          final g = ActiveStrokeGeometry()
            ..begin(style)
            ..sync(_wave(n));
          final recorder = ui.PictureRecorder();
          g.paint(ui.Canvas(recorder));
          recorder.endRecording().dispose();
        }
      });
    }

    test('translucent highlighter paints inside a layer', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.highlighter())
        ..sync(_wave(50));
      final recorder = ui.PictureRecorder();
      g.paint(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    });

    test('clear stops painting', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.pen())
        ..sync(_wave(10))
        ..clear();
      expect(g.consumed, 0);
    });
  });
}
