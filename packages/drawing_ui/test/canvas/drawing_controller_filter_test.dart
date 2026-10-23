import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:flutter_test/flutter_test.dart';

List<DrawingPoint> _noisyLine() {
  final rnd = math.Random(7);
  return [
    for (var i = 0; i <= 100; i++)
      DrawingPoint(
        x: 10.0 + i * 3,
        y: 50.0 + (rnd.nextDouble() - 0.5) * 3,
        timestamp: i * 8,
      ),
  ];
}

Stroke _run(DrawingController c, List<DrawingPoint> pts) {
  c.startStroke(pts.first, StrokeStyle.pen());
  for (final p in pts.skip(1)) {
    c.addPoint(p);
  }
  return c.endStroke()!;
}

void main() {
  test('filter keeps noisy line near ideal and raw endpoints', () {
    final pts = _noisyLine();
    final stroke = _run(DrawingController(), pts);
    for (final p in stroke.points.skip(20)) {
      expect((p.y - 50).abs(), lessThan(0.5));
    }
    expect(stroke.points.first.x, pts.first.x);
    expect(stroke.points.last.x, pts.last.x);
    expect(stroke.points.last.y, pts.last.y);
  });

  test('inputFilter null reproduces raw points', () {
    final pts = _noisyLine();
    final stroke = _run(DrawingController(inputFilter: null), pts);
    expect(stroke.points, pts);
  });

  test('straight line mode bypasses the filter', () {
    final pts = _noisyLine();
    final c = DrawingController();
    c.startStroke(pts.first, StrokeStyle.pen(), straightLine: true);
    for (final p in pts.skip(1)) {
      c.addPoint(p);
    }
    final stroke = c.endStroke()!;
    expect(stroke.points, [pts.first, pts.last]);
  });
}
