import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../models/drawing_point.dart';

/// Provides algorithms for smoothing stroke paths.
///
/// Smoothing reduces jitter from hand tremor and improves stroke quality
/// while maintaining the overall shape and feel of the original input.
class PathSmoother {
  /// Creates a path smoother with the given configuration.
  const PathSmoother({
    this.smoothingFactor = 0.5,
    this.minDistance = 2.0,
    this.tensionFactor = 0.5,
  });

  /// How much smoothing to apply (0.0 = none, 1.0 = maximum).
  final double smoothingFactor;

  /// Minimum distance between points before adding a new one.
  final double minDistance;

  /// Tension factor for spline interpolation.
  final double tensionFactor;

  /// Applies moving average smoothing to a list of points.
  ///
  /// This is a simple smoothing algorithm suitable for real-time use.
  List<DrawingPoint> smoothMovingAverage(
    List<DrawingPoint> points, {
    int windowSize = 3,
  }) {
    if (points.length < windowSize) return List.of(points);

    final smoothed = <DrawingPoint>[];
    final halfWindow = windowSize ~/ 2;

    for (int i = 0; i < points.length; i++) {
      final start = math.max(0, i - halfWindow);
      final end = math.min(points.length, i + halfWindow + 1);
      final window = points.sublist(start, end);

      double sumX = 0, sumY = 0, sumPressure = 0, sumTilt = 0;
      for (final p in window) {
        sumX += p.x;
        sumY += p.y;
        sumPressure += p.pressure;
        sumTilt += p.tilt;
      }

      final count = window.length;
      smoothed.add(DrawingPoint(
        position: Offset(sumX / count, sumY / count),
        pressure: sumPressure / count,
        tilt: sumTilt / count,
        timestamp: points[i].timestamp,
      ));
    }

    // Preserve original start and end points
    if (smoothed.isNotEmpty) {
      smoothed[0] = points.first;
      smoothed[smoothed.length - 1] = points.last;
    }

    return smoothed;
  }

  /// Applies Gaussian smoothing to a list of points.
  ///
  /// Gaussian smoothing provides better quality than moving average
  /// but is more computationally expensive.
  List<DrawingPoint> smoothGaussian(
    List<DrawingPoint> points, {
    double sigma = 1.0,
  }) {
    if (points.length < 3) return List.of(points);

    final kernel = _generateGaussianKernel(sigma);
    final halfSize = kernel.length ~/ 2;
    final smoothed = <DrawingPoint>[];

    for (int i = 0; i < points.length; i++) {
      double sumX = 0, sumY = 0, sumPressure = 0, sumTilt = 0;
      double sumWeights = 0;

      for (int k = 0; k < kernel.length; k++) {
        final j = i + k - halfSize;
        if (j >= 0 && j < points.length) {
          final weight = kernel[k];
          sumX += points[j].x * weight;
          sumY += points[j].y * weight;
          sumPressure += points[j].pressure * weight;
          sumTilt += points[j].tilt * weight;
          sumWeights += weight;
        }
      }

      smoothed.add(DrawingPoint(
        position: Offset(sumX / sumWeights, sumY / sumWeights),
        pressure: sumPressure / sumWeights,
        tilt: sumTilt / sumWeights,
        timestamp: points[i].timestamp,
      ));
    }

    // Preserve endpoints
    if (smoothed.isNotEmpty) {
      smoothed[0] = points.first;
      smoothed[smoothed.length - 1] = points.last;
    }

    return smoothed;
  }

  /// Generates Catmull-Rom spline points for smooth curves.
  ///
  /// This provides very smooth curves suitable for final rendering.
  List<DrawingPoint> interpolateCatmullRom(
    List<DrawingPoint> points, {
    int segmentsPerSpan = 4,
  }) {
    if (points.length < 4) return List.of(points);

    final result = <DrawingPoint>[];

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[math.min(points.length - 1, i + 1)];
      final p3 = points[math.min(points.length - 1, i + 2)];

      for (int j = 0; j < segmentsPerSpan; j++) {
        final t = j / segmentsPerSpan;
        result.add(_catmullRomPoint(p0, p1, p2, p3, t, tensionFactor));
      }
    }

    result.add(points.last);
    return result;
  }

  /// Reduces points while preserving shape using Douglas-Peucker algorithm.
  ///
  /// Use this to reduce point count for performance or storage.
  List<DrawingPoint> simplifyDouglasPeucker(
    List<DrawingPoint> points, {
    double epsilon = 1.0,
  }) {
    if (points.length < 3) return List.of(points);

    return _douglasPeuckerRecursive(points, epsilon);
  }

  /// Filters points that are too close together.
  List<DrawingPoint> filterByDistance(List<DrawingPoint> points) {
    if (points.isEmpty) return [];

    final result = <DrawingPoint>[points.first];
    for (int i = 1; i < points.length; i++) {
      final distance = (points[i].position - result.last.position).distance;
      if (distance >= minDistance) {
        result.add(points[i]);
      }
    }

    // Always include last point
    if (result.last != points.last) {
      result.add(points.last);
    }

    return result;
  }

  List<double> _generateGaussianKernel(double sigma) {
    final size = (sigma * 6).ceil() | 1; // Ensure odd
    final kernel = List<double>.filled(size, 0);
    final center = size ~/ 2;
    double sum = 0;

    for (int i = 0; i < size; i++) {
      final x = (i - center).toDouble();
      kernel[i] = math.exp(-x * x / (2 * sigma * sigma));
      sum += kernel[i];
    }

    // Normalize
    for (int i = 0; i < size; i++) {
      kernel[i] /= sum;
    }

    return kernel;
  }

  DrawingPoint _catmullRomPoint(
    DrawingPoint p0,
    DrawingPoint p1,
    DrawingPoint p2,
    DrawingPoint p3,
    double t,
    double tension,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    final s = (1 - tension) / 2;

    final x = s * ((-t3 + 2 * t2 - t) * p0.x +
            (3 * t3 - 5 * t2 + 2) * p1.x +
            (-3 * t3 + 4 * t2 + t) * p2.x +
            (t3 - t2) * p3.x);

    final y = s * ((-t3 + 2 * t2 - t) * p0.y +
            (3 * t3 - 5 * t2 + 2) * p1.y +
            (-3 * t3 + 4 * t2 + t) * p2.y +
            (t3 - t2) * p3.y);

    final pressure = p1.pressure + (p2.pressure - p1.pressure) * t;
    final tilt = p1.tilt + (p2.tilt - p1.tilt) * t;

    return DrawingPoint(
      position: Offset(x, y),
      pressure: pressure,
      tilt: tilt,
    );
  }

  List<DrawingPoint> _douglasPeuckerRecursive(
    List<DrawingPoint> points,
    double epsilon,
  ) {
    if (points.length < 3) return List.of(points);

    // Find point with max distance from line
    double maxDist = 0;
    int maxIndex = 0;

    final first = points.first.position;
    final last = points.last.position;

    for (int i = 1; i < points.length - 1; i++) {
      final dist = _perpendicularDistance(points[i].position, first, last);
      if (dist > maxDist) {
        maxDist = dist;
        maxIndex = i;
      }
    }

    if (maxDist > epsilon) {
      // Recursive simplification
      final left = _douglasPeuckerRecursive(
        points.sublist(0, maxIndex + 1),
        epsilon,
      );
      final right = _douglasPeuckerRecursive(
        points.sublist(maxIndex),
        epsilon,
      );

      // Combine (avoid duplicate at maxIndex)
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // Just keep endpoints
      return [points.first, points.last];
    }
  }

  double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    if (dx == 0 && dy == 0) {
      return (point - lineStart).distance;
    }

    final t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        (dx * dx + dy * dy);

    final nearest = Offset(
      lineStart.dx + t * dx,
      lineStart.dy + t * dy,
    );

    return (point - nearest).distance;
  }
}
