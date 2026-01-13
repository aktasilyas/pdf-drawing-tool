import 'package:test/test.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/input/path_smoother.dart';

void main() {
  group('PathSmoother', () {
    group('smooth', () {
      test('returns copy of list with fewer than 3 points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 10),
        ];

        final result = PathSmoother.smooth(points);

        expect(result.length, 2);
        expect(result[0].x, 0);
        expect(result[1].x, 10);
      });

      test('returns copy of empty list', () {
        final points = <DrawingPoint>[];
        final result = PathSmoother.smooth(points);
        expect(result, isEmpty);
      });

      test('returns copy of single point', () {
        final points = [DrawingPoint(x: 5, y: 5)];
        final result = PathSmoother.smooth(points);
        expect(result.length, 1);
        expect(result[0].x, 5);
      });

      test('smooths 3+ points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 20), // Will be smoothed
          DrawingPoint(x: 20, y: 0),
        ];

        final result = PathSmoother.smooth(points, tension: 1.0);

        expect(result.length, 3);
        // First and last preserved
        expect(result[0].x, 0);
        expect(result[2].x, 20);
        // Middle point smoothed toward average
        // Average x = (0 + 10 + 20) / 3 = 10 (same)
        // Average y = (0 + 20 + 0) / 3 ≈ 6.67
        expect(result[1].y, closeTo(6.67, 0.01));
      });

      test('preserves first and last points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 5, y: 5),
          DrawingPoint(x: 10, y: 0),
          DrawingPoint(x: 15, y: 5),
          DrawingPoint(x: 20, y: 0),
        ];

        final result = PathSmoother.smooth(points);

        expect(result.first.x, 0);
        expect(result.first.y, 0);
        expect(result.last.x, 20);
        expect(result.last.y, 0);
      });

      test('tension 0.0 produces minimal change', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 100),
          DrawingPoint(x: 20, y: 0),
        ];

        final result = PathSmoother.smooth(points, tension: 0.0);

        // Middle point should be nearly unchanged
        expect(result[1].x, closeTo(10, 0.01));
        expect(result[1].y, closeTo(100, 0.01));
      });

      test('tension 1.0 produces maximum smoothing', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 100),
          DrawingPoint(x: 20, y: 0),
        ];

        final result = PathSmoother.smooth(points, tension: 1.0);

        // Middle point should be at average: (0 + 100 + 0) / 3 ≈ 33.33
        expect(result[1].y, closeTo(33.33, 0.01));
      });

      test('multiple iterations produce smoother result', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 5, y: 50),
          DrawingPoint(x: 10, y: 0),
          DrawingPoint(x: 15, y: 50),
          DrawingPoint(x: 20, y: 0),
        ];

        final onePass = PathSmoother.smooth(points, iterations: 1);
        final threePasses = PathSmoother.smooth(points, iterations: 3);

        // More iterations = smoother (less variance from mean)
        final onePassVariance = _calculateYVariance(onePass);
        final threePassVariance = _calculateYVariance(threePasses);

        expect(threePassVariance, lessThan(onePassVariance));
      });

      test('preserves point count', () {
        final points = List.generate(
          10,
          (i) => DrawingPoint(x: i * 10.0, y: (i % 2) * 20.0),
        );

        final result = PathSmoother.smooth(points);

        expect(result.length, points.length);
      });

      test('smooths pressure values', () {
        final points = [
          DrawingPoint(x: 0, y: 0, pressure: 0.0),
          DrawingPoint(x: 10, y: 10, pressure: 1.0),
          DrawingPoint(x: 20, y: 0, pressure: 0.0),
        ];

        final result = PathSmoother.smooth(points, tension: 1.0);

        // Middle pressure should be smoothed: (0 + 1 + 0) / 3 ≈ 0.33
        expect(result[1].pressure, closeTo(0.33, 0.01));
      });

      test('smooths tilt values', () {
        final points = [
          DrawingPoint(x: 0, y: 0, tilt: 0.0),
          DrawingPoint(x: 10, y: 10, tilt: 0.6),
          DrawingPoint(x: 20, y: 0, tilt: 0.0),
        ];

        final result = PathSmoother.smooth(points, tension: 1.0);

        // Middle tilt should be smoothed: (0 + 0.6 + 0) / 3 = 0.2
        expect(result[1].tilt, closeTo(0.2, 0.01));
      });

      test('preserves timestamps', () {
        final points = [
          DrawingPoint(x: 0, y: 0, timestamp: 100),
          DrawingPoint(x: 10, y: 10, timestamp: 200),
          DrawingPoint(x: 20, y: 0, timestamp: 300),
        ];

        final result = PathSmoother.smooth(points);

        expect(result[0].timestamp, 100);
        expect(result[1].timestamp, 200);
        expect(result[2].timestamp, 300);
      });

      test('clamps tension to valid range', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 100),
          DrawingPoint(x: 20, y: 0),
        ];

        // Should not throw with out-of-range values
        final result1 = PathSmoother.smooth(points, tension: -1.0);
        final result2 = PathSmoother.smooth(points, tension: 2.0);

        expect(result1.length, 3);
        expect(result2.length, 3);
      });
    });

    group('simplify', () {
      test('returns copy of list with fewer than 3 points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 10),
        ];

        final result = PathSmoother.simplify(points);

        expect(result.length, 2);
      });

      test('removes close points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 0.5, y: 0.5), // Close to first
          DrawingPoint(x: 0.8, y: 0.8), // Close to previous
          DrawingPoint(x: 10, y: 10),
        ];

        final result = PathSmoother.simplify(points, tolerance: 2.0);

        // Should keep first, skip close ones, keep last
        expect(result.length, lessThan(points.length));
        expect(result.first.x, 0);
        expect(result.last.x, 10);
      });

      test('preserves distant points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 10),
          DrawingPoint(x: 20, y: 20),
          DrawingPoint(x: 30, y: 30),
        ];

        final result = PathSmoother.simplify(points, tolerance: 1.0);

        // All points are distant, should keep all
        expect(result.length, 4);
      });

      test('always preserves first and last points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 0.1, y: 0.1),
          DrawingPoint(x: 0.2, y: 0.2),
          DrawingPoint(x: 0.3, y: 0.3),
        ];

        final result = PathSmoother.simplify(points, tolerance: 10.0);

        expect(result.first.x, 0);
        expect(result.last.x, 0.3);
      });

      test('tolerance affects simplification level', () {
        final points = List.generate(
          20,
          (i) => DrawingPoint(x: i * 1.0, y: i * 1.0),
        );

        final lowTolerance = PathSmoother.simplify(points, tolerance: 0.5);
        final highTolerance = PathSmoother.simplify(points, tolerance: 5.0);

        expect(highTolerance.length, lessThanOrEqualTo(lowTolerance.length));
      });

      test('returns empty list for empty input', () {
        final result = PathSmoother.simplify([]);
        expect(result, isEmpty);
      });
    });

    group('interpolate', () {
      test('t=0.0 returns point a', () {
        final a = DrawingPoint(x: 0, y: 0, pressure: 0.2, tilt: 0.1);
        final b = DrawingPoint(x: 100, y: 100, pressure: 1.0, tilt: 0.5);

        final result = PathSmoother.interpolate(a, b, 0.0);

        expect(result.x, 0);
        expect(result.y, 0);
        expect(result.pressure, 0.2);
        expect(result.tilt, 0.1);
      });

      test('t=1.0 returns point b', () {
        final a = DrawingPoint(x: 0, y: 0, pressure: 0.2, tilt: 0.1);
        final b = DrawingPoint(x: 100, y: 100, pressure: 1.0, tilt: 0.5);

        final result = PathSmoother.interpolate(a, b, 1.0);

        expect(result.x, 100);
        expect(result.y, 100);
        expect(result.pressure, 1.0);
        expect(result.tilt, 0.5);
      });

      test('t=0.5 returns midpoint', () {
        final a = DrawingPoint(x: 0, y: 0, pressure: 0.0, tilt: 0.0);
        final b = DrawingPoint(x: 100, y: 100, pressure: 1.0, tilt: 1.0);

        final result = PathSmoother.interpolate(a, b, 0.5);

        expect(result.x, 50);
        expect(result.y, 50);
        expect(result.pressure, 0.5);
        expect(result.tilt, 0.5);
      });

      test('interpolates pressure correctly', () {
        final a = DrawingPoint(x: 0, y: 0, pressure: 0.2);
        final b = DrawingPoint(x: 10, y: 10, pressure: 0.8);

        final result = PathSmoother.interpolate(a, b, 0.5);

        expect(result.pressure, 0.5);
      });

      test('interpolates tilt correctly', () {
        final a = DrawingPoint(x: 0, y: 0, tilt: 0.0);
        final b = DrawingPoint(x: 10, y: 10, tilt: 0.4);

        final result = PathSmoother.interpolate(a, b, 0.25);

        expect(result.tilt, 0.1);
      });

      test('interpolates timestamp', () {
        final a = DrawingPoint(x: 0, y: 0, timestamp: 0);
        final b = DrawingPoint(x: 10, y: 10, timestamp: 100);

        final result = PathSmoother.interpolate(a, b, 0.5);

        expect(result.timestamp, 50);
      });

      test('clamps t to valid range', () {
        final a = DrawingPoint(x: 0, y: 0);
        final b = DrawingPoint(x: 100, y: 100);

        final belowZero = PathSmoother.interpolate(a, b, -0.5);
        final aboveOne = PathSmoother.interpolate(a, b, 1.5);

        expect(belowZero.x, 0);
        expect(aboveOne.x, 100);
      });

      test('handles negative coordinates', () {
        final a = DrawingPoint(x: -50, y: -50);
        final b = DrawingPoint(x: 50, y: 50);

        final result = PathSmoother.interpolate(a, b, 0.5);

        expect(result.x, 0);
        expect(result.y, 0);
      });
    });

    group('distance', () {
      test('returns 0 for same point', () {
        final point = DrawingPoint(x: 10, y: 20);
        expect(PathSmoother.distance(point, point), 0);
      });

      test('calculates horizontal distance', () {
        final a = DrawingPoint(x: 0, y: 0);
        final b = DrawingPoint(x: 10, y: 0);
        expect(PathSmoother.distance(a, b), 10);
      });

      test('calculates vertical distance', () {
        final a = DrawingPoint(x: 0, y: 0);
        final b = DrawingPoint(x: 0, y: 10);
        expect(PathSmoother.distance(a, b), 10);
      });

      test('calculates diagonal distance', () {
        final a = DrawingPoint(x: 0, y: 0);
        final b = DrawingPoint(x: 3, y: 4);
        expect(PathSmoother.distance(a, b), 5); // 3-4-5 triangle
      });
    });

    group('pathLength', () {
      test('returns 0 for empty path', () {
        expect(PathSmoother.pathLength([]), 0);
      });

      test('returns 0 for single point', () {
        final points = [DrawingPoint(x: 0, y: 0)];
        expect(PathSmoother.pathLength(points), 0);
      });

      test('calculates correct length for straight line', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 0),
        ];
        expect(PathSmoother.pathLength(points), 10);
      });

      test('calculates correct length for multi-segment path', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 0), // +10
          DrawingPoint(x: 10, y: 10), // +10
        ];
        expect(PathSmoother.pathLength(points), 20);
      });
    });
  });
}

/// Helper function to calculate Y variance for smoothness comparison.
double _calculateYVariance(List<DrawingPoint> points) {
  if (points.isEmpty) return 0;

  final mean = points.map((p) => p.y).reduce((a, b) => a + b) / points.length;
  final variance =
      points.map((p) => (p.y - mean) * (p.y - mean)).reduce((a, b) => a + b) /
          points.length;

  return variance;
}
