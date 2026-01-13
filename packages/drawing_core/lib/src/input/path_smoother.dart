import 'dart:math' as math;

import 'package:drawing_core/src/internal.dart';

/// Utility class for smoothing and simplifying drawing paths.
///
/// All methods are static and stateless, making this a pure utility class.
/// These algorithms help improve the quality of hand-drawn strokes.
class PathSmoother {
  // Private constructor to prevent instantiation
  PathSmoother._();

  /// Smooths a list of points using moving average.
  ///
  /// [points] - The list of points to smooth.
  /// [tension] - Smoothing intensity (0.0 = none, 1.0 = maximum). Default 0.5.
  /// [iterations] - Number of smoothing passes. Default 1.
  ///
  /// Returns a new list with smoothed points. The first and last points
  /// are preserved to maintain stroke endpoints.
  ///
  /// If there are fewer than 3 points, returns a copy of the original list.
  static List<DrawingPoint> smooth(
    List<DrawingPoint> points, {
    double tension = 0.5,
    int iterations = 1,
  }) {
    if (points.length < 3) {
      return List.from(points);
    }

    // Clamp tension to valid range
    tension = tension.clamp(0.0, 1.0);
    iterations = iterations.clamp(1, 10);

    List<DrawingPoint> result = List.from(points);

    for (var iter = 0; iter < iterations; iter++) {
      final smoothed = <DrawingPoint>[];

      // Keep first point unchanged
      smoothed.add(result.first);

      // Smooth middle points using weighted moving average
      for (var i = 1; i < result.length - 1; i++) {
        final prev = result[i - 1];
        final curr = result[i];
        final next = result[i + 1];

        // Calculate smoothed values
        final avgX = (prev.x + curr.x + next.x) / 3;
        final avgY = (prev.y + curr.y + next.y) / 3;
        final avgPressure = (prev.pressure + curr.pressure + next.pressure) / 3;
        final avgTilt = (prev.tilt + curr.tilt + next.tilt) / 3;

        // Interpolate between original and smoothed based on tension
        final newX = curr.x + (avgX - curr.x) * tension;
        final newY = curr.y + (avgY - curr.y) * tension;
        final newPressure = curr.pressure + (avgPressure - curr.pressure) * tension;
        final newTilt = curr.tilt + (avgTilt - curr.tilt) * tension;

        smoothed.add(DrawingPoint(
          x: newX,
          y: newY,
          pressure: newPressure,
          tilt: newTilt,
          timestamp: curr.timestamp,
        ));
      }

      // Keep last point unchanged
      smoothed.add(result.last);

      result = smoothed;
    }

    return result;
  }

  /// Simplifies a list of points by removing points that are too close together.
  ///
  /// [points] - The list of points to simplify.
  /// [tolerance] - Minimum distance between points. Default 1.0.
  ///
  /// Returns a new list with redundant points removed. The first and last
  /// points are always preserved.
  ///
  /// This is useful for reducing stroke complexity and improving performance.
  static List<DrawingPoint> simplify(
    List<DrawingPoint> points, {
    double tolerance = 1.0,
  }) {
    if (points.length < 3) {
      return List.from(points);
    }

    tolerance = tolerance.clamp(0.1, 100.0);
    final toleranceSquared = tolerance * tolerance;

    final result = <DrawingPoint>[];

    // Always keep first point
    result.add(points.first);

    DrawingPoint lastKept = points.first;

    // Check each point against the last kept point
    for (var i = 1; i < points.length - 1; i++) {
      final point = points[i];
      final dx = point.x - lastKept.x;
      final dy = point.y - lastKept.y;
      final distanceSquared = dx * dx + dy * dy;

      // Keep point if it's far enough from the last kept point
      if (distanceSquared >= toleranceSquared) {
        result.add(point);
        lastKept = point;
      }
    }

    // Always keep last point
    result.add(points.last);

    return result;
  }

  /// Interpolates between two points.
  ///
  /// [a] - The starting point (t = 0.0).
  /// [b] - The ending point (t = 1.0).
  /// [t] - Interpolation factor (0.0 to 1.0).
  ///
  /// Returns a new point at the interpolated position.
  /// All properties (x, y, pressure, tilt) are interpolated.
  /// Timestamp is interpolated as well (rounded to int).
  static DrawingPoint interpolate(
    DrawingPoint a,
    DrawingPoint b,
    double t,
  ) {
    t = t.clamp(0.0, 1.0);

    return DrawingPoint(
      x: a.x + (b.x - a.x) * t,
      y: a.y + (b.y - a.y) * t,
      pressure: a.pressure + (b.pressure - a.pressure) * t,
      tilt: a.tilt + (b.tilt - a.tilt) * t,
      timestamp: (a.timestamp + (b.timestamp - a.timestamp) * t).round(),
    );
  }

  /// Calculates the distance between two points.
  ///
  /// Returns the Euclidean distance.
  static double distance(DrawingPoint a, DrawingPoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates the total length of a path.
  ///
  /// Returns the sum of distances between consecutive points.
  static double pathLength(List<DrawingPoint> points) {
    if (points.length < 2) return 0.0;

    double length = 0.0;
    for (var i = 1; i < points.length; i++) {
      length += distance(points[i - 1], points[i]);
    }
    return length;
  }
}
