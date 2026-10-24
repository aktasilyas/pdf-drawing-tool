import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

bool _segmentsCross(Point2D a, Point2D b, Point2D c, Point2D d) {
  double cross(Point2D o, Point2D p, Point2D q) =>
      (p.x - o.x) * (q.y - o.y) - (p.y - o.y) * (q.x - o.x);
  final d1 = cross(c, d, a), d2 = cross(c, d, b);
  final d3 = cross(a, b, c), d4 = cross(a, b, d);
  return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
}

int _selfIntersections(List<Point2D> poly) {
  var count = 0;
  final n = poly.length;
  for (var i = 0; i < n; i++) {
    for (var j = i + 2; j < n; j++) {
      if (i == 0 && j == n - 1) continue;
      if (_segmentsCross(
          poly[i], poly[(i + 1) % n], poly[j], poly[(j + 1) % n])) {
        count++;
      }
    }
  }
  return count;
}

List<DrawingPoint> _line(int count, {double pressure = 1}) => [
      for (var i = 0; i < count; i++)
        DrawingPoint(
          x: i * 200 / (count - 1),
          y: 50,
          pressure: pressure,
          timestamp: i * 8,
        ),
    ];

void main() {
  const options = StrokeOutlineOptions(size: 6);

  test('empty input gives empty outline', () {
    expect(StrokeOutline.build([], options), isEmpty);
  });

  test('single point gives a closed circle of the expected radius', () {
    final o = StrokeOutline.build([DrawingPoint(x: 10, y: 10)], options);
    expect(o.length, greaterThan(8));
    for (final p in o) {
      expect(math.sqrt(math.pow(p.x - 10, 2) + math.pow(p.y - 10, 2)),
          closeTo(3, 1.0));
    }
  });

  test('outline is closed, finite and has no self-intersections', () {
    final o = StrokeOutline.build(_line(40), options);
    expect(o.length, greaterThan(40));
    expect(o.every((p) => p.x.isFinite && p.y.isFinite), isTrue);
    expect(_selfIntersections(o), 0);
  });

  test('no kinks when sample density changes abruptly', () {
    final pts = <DrawingPoint>[
      for (var i = 0; i < 10; i++)
        DrawingPoint(x: i * 20.0, y: 0, pressure: 0.2, timestamp: i * 8),
      for (var i = 0; i < 60; i++)
        DrawingPoint(
            x: 180 + i * 0.5, y: 0, pressure: 1.0, timestamp: 80 + i * 8),
      for (var i = 1; i < 10; i++)
        DrawingPoint(
            x: 210 + i * 25.0, y: 0, pressure: 0.3, timestamp: 600 + i * 8),
    ];
    expect(_selfIntersections(StrokeOutline.build(pts, options)), 0);
  });

  test('curved stroke with pressure ramp has no self-intersections', () {
    final pts = [
      for (var i = 0; i < 80; i++)
        DrawingPoint(
          x: 100 + 80 * math.cos(i / 80 * math.pi),
          y: 100 + 80 * math.sin(i / 80 * math.pi),
          pressure: i / 79,
          timestamp: i * 8,
        ),
    ];
    expect(_selfIntersections(StrokeOutline.build(pts, options)), 0);
  });

  double width(List<Point2D> o) {
    final ys = o.map((p) => p.y);
    return ys.reduce(math.max) - ys.reduce(math.min);
  }

  test('higher pressure gives a wider outline', () {
    final low = width(StrokeOutline.build(_line(30, pressure: 0.1), options));
    final high = width(StrokeOutline.build(_line(30, pressure: 1), options));
    expect(high, greaterThan(low * 1.5));
  });

  test('tapers narrow the stroke ends', () {
    const tapered = StrokeOutlineOptions(size: 10, taperStart: 40, taperEnd: 40);
    final o = StrokeOutline.build(_line(60), tapered);
    final nearStart = o.where((p) => p.x < 10).map((p) => (p.y - 50).abs());
    final mid = o.where((p) => (p.x - 100).abs() < 5).map((p) => (p.y - 50).abs());
    expect(nearStart.reduce(math.max), lessThan(mid.reduce(math.max)));
  });
}
