import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

List<DrawingPoint> _sine(int n) => [
      for (var i = 0; i < n; i++)
        DrawingPoint(
          x: i * 3.0,
          y: 40 * math.sin(i / 9),
          pressure: 0.3 + 0.7 * ((i % 40) / 40),
          timestamp: i * 8,
        ),
    ];

List<DrawingPoint> _spiral(int n) => [
      for (var i = 0; i < n; i++)
        DrawingPoint(
          x: 100 + (5 + i * 0.4) * math.cos(i / 4),
          y: 100 + (5 + i * 0.4) * math.sin(i / 4),
          pressure: 0.5,
          timestamp: i * 8,
        ),
    ];

List<DrawingPoint> _zigzag(int n) => [
      for (var i = 0; i < n; i++)
        DrawingPoint(
          x: i * 2.0,
          y: (i % 6 < 3 ? 1 : -1) * 15.0,
          pressure: 1,
          timestamp: i * 5,
        ),
    ];

List<DrawingPoint> _ramp(int n) => [
      for (var i = 0; i < n; i++)
        DrawingPoint(
          x: i * 1.5,
          y: 10 * math.cos(i / 15),
          pressure: i / (n - 1),
          timestamp: i * 8,
        ),
    ];

double _polygonArea(List<Point2D> p) {
  var a = 0.0;
  for (var i = 0; i < p.length; i++) {
    final q = p[(i + 1) % p.length];
    a += p[i].x * q.y - q.x * p[i].y;
  }
  return a.abs() / 2;
}

void _expectParity(
  List<DrawingPoint> pts,
  StrokeOutlineOptions options, {
  int step = 1,
}) {
  final inc = IncrementalStrokeOutline(options);
  for (var n = 1; n <= pts.length; n++) {
    inc.addAll([pts[n - 1]]);
    if (n % step != 0 && n != pts.length) continue;
    final expected = StrokeOutline.build(pts.sublist(0, n), options);
    final actual = inc.toPolygon();
    expect(actual.length, expected.length, reason: 'prefix $n length');
    for (var i = 0; i < expected.length; i++) {
      expect((actual[i].x - expected[i].x).abs(), lessThan(1e-3),
          reason: 'prefix $n point $i x');
      expect((actual[i].y - expected[i].y).abs(), lessThan(1e-3),
          reason: 'prefix $n point $i y');
    }
  }
}

void main() {
  group('prefix parity with StrokeOutline.build', () {
    const base = StrokeOutlineOptions(size: 8);
    final strokes = <String, List<DrawingPoint>>{
      'sine': _sine(160),
      'spiral': _spiral(160),
      'zigzag': _zigzag(120),
      'pressure ramp': _ramp(160),
    };
    for (final e in strokes.entries) {
      test('${e.key} with defaults', () => _expectParity(e.value, base));
    }

    for (final smoothing in [0.0, 0.5, 1.0]) {
      for (final streamline in [0.0, 1.0]) {
        test('sine smoothing $smoothing streamline $streamline', () {
          _expectParity(
            _sine(120),
            StrokeOutlineOptions(
                size: 8, smoothing: smoothing, streamline: streamline),
          );
        });
      }
    }

    test('tapered start and end', () {
      _expectParity(
        _sine(140),
        const StrokeOutlineOptions(size: 10, taperStart: 30, taperEnd: 40),
      );
    });

    test('large taper end on a spiral', () {
      _expectParity(
        _spiral(120),
        const StrokeOutlineOptions(size: 6, taperEnd: 120, smoothing: 1),
      );
    });

    test('batched addAll matches build', () {
      final pts = _sine(300);
      final inc = IncrementalStrokeOutline(base)..addAll(pts);
      final expected = StrokeOutline.build(pts, base);
      final actual = inc.toPolygon();
      expect(actual.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        expect(actual[i].x, closeTo(expected[i].x, 1e-3));
        expect(actual[i].y, closeTo(expected[i].y, 1e-3));
      }
    });
  });

  group('bounded work per update', () {
    for (final n in [50, 500, 5000]) {
      test('lastRecomputed is bounded at n = $n', () {
        const options = StrokeOutlineOptions(size: 6);
        final pts = _sine(n);
        final inc = IncrementalStrokeOutline(options);
        var worst = 0;
        for (final p in pts) {
          inc.addAll([p]);
          worst = math.max(worst, inc.lastRecomputed);
        }
        expect(worst, lessThanOrEqualTo(24));
        if (n > 100) expect(inc.frozenCount, greaterThan(n ~/ 2));
      });
    }

    test('bound at maximum smoothing is still independent of n', () {
      const options = StrokeOutlineOptions(size: 6, smoothing: 1);
      final inc = IncrementalStrokeOutline(options);
      var worst = 0;
      for (final p in _sine(3000)) {
        inc.addAll([p]);
        worst = math.max(worst, inc.lastRecomputed);
      }
      expect(worst, lessThanOrEqualTo(80));
    });
  });

  group('edge cases', () {
    const options = StrokeOutlineOptions(size: 6);

    test('empty gives an empty polygon', () {
      final inc = IncrementalStrokeOutline(options);
      expect(inc.toPolygon(), isEmpty);
      final out = <double>[];
      inc.writeTail(out);
      expect(out, isEmpty);
    });

    test('single point and duplicates give the dot', () {
      final p = DrawingPoint(x: 10, y: 10, timestamp: 0);
      final inc = IncrementalStrokeOutline(options)..addAll([p, p, p]);
      final expected = StrokeOutline.build([p, p, p], options);
      final actual = inc.toPolygon();
      expect(actual.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        expect(actual[i].x, closeTo(expected[i].x, 1e-9));
        expect(actual[i].y, closeTo(expected[i].y, 1e-9));
      }
      final out = <double>[];
      inc.writeTail(out);
      expect(out.length, expected.length * 2);
    });

    test('reset clears state and can change options', () {
      final inc = IncrementalStrokeOutline(options)..addAll(_sine(100));
      inc.reset(const StrokeOutlineOptions(size: 12));
      expect(inc.frozenCount, 0);
      expect(inc.toPolygon(), isEmpty);
      final pts = _sine(30);
      inc.addAll(pts);
      final expected =
          StrokeOutline.build(pts, const StrokeOutlineOptions(size: 12));
      expect(inc.toPolygon().length, expected.length);
    });

    test('writeFrozen with an invalid range throws', () {
      final inc = IncrementalStrokeOutline(options)..addAll(_sine(100));
      expect(() => inc.writeFrozen(0, inc.frozenCount, <double>[]),
          throwsRangeError);
    });
  });

  group('frozen chunks plus tail cover the outline', () {
    test('summed chunk and tail areas are close to the full area', () {
      const options = StrokeOutlineOptions(size: 8);
      final pts = _sine(400);
      final inc = IncrementalStrokeOutline(options)..addAll(pts);
      final full = _polygonArea(inc.toPolygon());
      expect(inc.frozenCount, greaterThan(100));

      // Chunks share one sample, as the renderer will build them.
      var covered = 0.0;
      var from = 0;
      while (from < inc.frozenCount - 1) {
        final to = math.min(from + 15, inc.frozenCount - 1);
        final out = <double>[];
        inc.writeFrozen(from, to, out);
        covered += _polygonArea([
          for (var i = 0; i < out.length; i += 2) Point2D(out[i], out[i + 1]),
        ]);
        from = to;
      }
      // The tail starts two samples before the boundary, so subtract the
      // overlap by measuring body + tail against the full area loosely.
      final tail = <double>[];
      inc.writeTail(tail);
      final tailArea = _polygonArea([
        for (var i = 0; i < tail.length; i += 2) Point2D(tail[i], tail[i + 1]),
      ]);
      expect(tail, isNotEmpty);
      // Cover without gaps: union is at least the full area, and the
      // overlap (two samples of ribbon) is small.
      expect(covered + tailArea, greaterThanOrEqualTo(full * 0.995));
      expect(covered + tailArea, lessThan(full * 1.02));
    });
  });
}
