import 'dart:math' as math;
import 'package:drawing_core/drawing_core.dart';
import 'package:pdf/pdf.dart';

/// Options for vector rendering.
class VectorRenderOptions {
  /// Whether to smooth strokes using bezier curves.
  final bool smoothStrokes;

  /// Whether to optimize paths by simplifying.
  final bool optimizePaths;

  /// Path simplification tolerance.
  final double simplificationTolerance;

  const VectorRenderOptions({
    this.smoothStrokes = true,
    this.optimizePaths = true,
    this.simplificationTolerance = 1.0,
  });
}

/// Helpers the vector PDF export uses: stroke preparation (simplify +
/// smooth), ARGB to PDF colour and per-pen line cap/join.
class VectorPDFRenderer {
  /// Default rendering options.
  final VectorRenderOptions defaultOptions;

  VectorPDFRenderer({
    VectorRenderOptions? defaultOptions,
  }) : defaultOptions = defaultOptions ?? const VectorRenderOptions();

  /// Calculates the length of a stroke path.
  double _strokeLength(Stroke stroke) {
    double length = 0.0;

    for (int i = 1; i < stroke.points.length; i++) {
      final p1 = stroke.points[i - 1];
      final p2 = stroke.points[i];

      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;

      length += math.sqrt(dx * dx + dy * dy);
    }

    return length;
  }

  /// Converts ARGB color to PDF color.
  PdfColor convertColor(int argbColor) {
    // Alpha channel is not used in basic PDF colors
    final r = (argbColor >> 16) & 0xFF;
    final g = (argbColor >> 8) & 0xFF;
    final b = argbColor & 0xFF;

    return PdfColor(r / 255, g / 255, b / 255);
  }

  /// Extracts alpha value (0.0 to 1.0) from ARGB color.
  double extractAlpha(int argbColor) {
    final a = (argbColor >> 24) & 0xFF;
    return a / 255;
  }

  /// Smooths a stroke path using moving average.
  List<DrawingPoint> _smooth(List<DrawingPoint> points) {
    if (points.length <= 2) {
      return points;
    }

    final smoothed = <DrawingPoint>[];
    smoothed.add(points.first); // Keep first point

    // Apply moving average
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      final x = (prev.x + curr.x + next.x) / 3;
      final y = (prev.y + curr.y + next.y) / 3;
      final pressure = (prev.pressure + curr.pressure + next.pressure) / 3;

      smoothed.add(DrawingPoint(x: x, y: y, pressure: pressure));
    }

    smoothed.add(points.last); // Keep last point
    return smoothed;
  }

  /// Simplifies a path using Douglas-Peucker algorithm.
  List<DrawingPoint> _simplify(
    List<DrawingPoint> points, {
    required double tolerance,
  }) {
    if (points.length <= 2) {
      return points;
    }

    return _douglasPeucker(points, 0, points.length - 1, tolerance);
  }

  /// Douglas-Peucker path simplification algorithm.
  List<DrawingPoint> _douglasPeucker(
    List<DrawingPoint> points,
    int start,
    int end,
    double tolerance,
  ) {
    if (end - start <= 1) {
      return [points[start], points[end]];
    }

    // Find the point with maximum distance
    double maxDistance = 0;
    int maxIndex = start;

    for (int i = start + 1; i < end; i++) {
      final distance = _perpendicularDistance(
        points[i],
        points[start],
        points[end],
      );

      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      final left = _douglasPeucker(points, start, maxIndex, tolerance);
      final right = _douglasPeucker(points, maxIndex, end, tolerance);

      // Combine results (remove duplicate middle point)
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points[start], points[end]];
    }
  }

  /// Calculates perpendicular distance from point to line.
  double _perpendicularDistance(
    DrawingPoint point,
    DrawingPoint lineStart,
    DrawingPoint lineEnd,
  ) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;

    if (dx == 0 && dy == 0) {
      // Line is a point
      return math.sqrt(
        math.pow(point.x - lineStart.x, 2) + math.pow(point.y - lineStart.y, 2),
      );
    }

    final numerator =
        ((point.x - lineStart.x) * dy - (point.y - lineStart.y) * dx).abs();
    final denominator = math.sqrt(dx * dx + dy * dy);

    return numerator / denominator;
  }

  /// Estimates rendering complexity (0-1, higher is more complex).
  double estimateComplexity(Stroke stroke) {
    final pointCount = stroke.points.length;
    final length = _strokeLength(stroke);

    // Normalize to 0-1 range
    final pointComplexity = (pointCount / 10000).clamp(0.0, 1.0);
    final lengthComplexity = (length / 50000).clamp(0.0, 1.0);

    return (pointComplexity + lengthComplexity) / 2;
  }

  /// Checks if stroke should be optimized.
  bool shouldOptimize(Stroke stroke) {
    return stroke.points.length > 1000 || estimateComplexity(stroke) > 0.5;
  }

  /// Applies rendering options to prepare stroke for export.
  List<DrawingPoint> prepareStroke(
    Stroke stroke, {
    VectorRenderOptions? options,
  }) {
    final opts = options ?? defaultOptions;
    var points = stroke.points;

    // Optimize path if needed
    if (opts.optimizePaths && shouldOptimize(stroke)) {
      points = _simplify(points, tolerance: opts.simplificationTolerance);
    }

    // Smooth stroke if enabled
    if (opts.smoothStrokes && points.length > 2) {
      points = _smooth(points);
    }

    return points;
  }

  /// Gets recommended PDF line cap style based on pen type.
  /// Returns: 0 = butt, 1 = round, 2 = square
  int getRecommendedLineCap(PenType penType) {
    switch (penType) {
      case PenType.ballpointPen:
      case PenType.pencil:
      case PenType.brushPen:
      case PenType.fountainPen:
        return 1; // Round
      case PenType.highlighter:
      case PenType.neonHighlighter:
      case PenType.dashedPen:
        return 2; // Square
      case PenType.gelPen:
      case PenType.hardPencil:
      case PenType.rulerPen:
        return 1; // Round
    }
  }

  /// Gets recommended PDF line join style based on pen type.
  /// Returns: 0 = miter, 1 = round, 2 = bevel
  int getRecommendedLineJoin(PenType penType) {
    switch (penType) {
      case PenType.ballpointPen:
      case PenType.pencil:
      case PenType.gelPen:
      case PenType.brushPen:
      case PenType.fountainPen:
        return 1; // Round
      case PenType.highlighter:
      case PenType.neonHighlighter:
      case PenType.dashedPen:
        return 0; // Miter
      case PenType.hardPencil:
      case PenType.rulerPen:
        return 1; // Round
    }
  }
}
