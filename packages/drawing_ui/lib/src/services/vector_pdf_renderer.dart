import 'dart:math' as math;
import 'package:drawing_core/drawing_core.dart';
import 'package:pdf/pdf.dart';

/// Options for vector rendering.
class VectorRenderOptions {
  /// Whether to smooth strokes using bezier curves.
  final bool smoothStrokes;

  /// Whether to enable antialiasing.
  final bool antialiasing;

  /// Whether to optimize paths by simplifying.
  final bool optimizePaths;

  /// Path simplification tolerance.
  final double simplificationTolerance;

  const VectorRenderOptions({
    this.smoothStrokes = true,
    this.antialiasing = true,
    this.optimizePaths = true,
    this.simplificationTolerance = 1.0,
  });
}

/// Enhanced vector PDF renderer with advanced features.
class VectorPDFRenderer {
  /// Whether antialiasing is enabled.
  final bool enableAntialiasing;

  /// Default rendering options.
  final VectorRenderOptions defaultOptions;

  VectorPDFRenderer({
    this.enableAntialiasing = true,
    VectorRenderOptions? defaultOptions,
  }) : defaultOptions = defaultOptions ?? const VectorRenderOptions();

  /// Checks if a stroke can be rendered.
  bool canRenderStroke(Stroke stroke) {
    return stroke.points.length >= 2;
  }

  /// Checks if a shape can be rendered.
  bool canRenderShape(Shape shape) {
    return shape.bounds.width > 0 && shape.bounds.height > 0;
  }

  /// Checks if text can be rendered.
  bool canRenderText(TextElement text) {
    return text.text.isNotEmpty;
  }

  /// Checks if a pen style is supported.
  bool supportsPenStyle(PenType penType) {
    // All pen types are supported in vector mode
    return true;
  }

  /// Calculates the length of a stroke path.
  double calculateStrokeLength(Stroke stroke) {
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

  /// Calculates the area of a shape.
  double calculateShapeArea(Shape shape) {
    switch (shape.type) {
      case ShapeType.rectangle:
        return shape.bounds.width * shape.bounds.height;

      case ShapeType.ellipse:
        final a = shape.bounds.width / 2;
        final b = shape.bounds.height / 2;
        return math.pi * a * b;

      case ShapeType.triangle:
        return (shape.bounds.width * shape.bounds.height) / 2;

      case ShapeType.diamond:
        return (shape.bounds.width * shape.bounds.height) / 2;

      case ShapeType.line:
      case ShapeType.arrow:
        return 0.0;

      case ShapeType.star:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
      case ShapeType.plus:
        // Approximate area for complex shapes
        return shape.bounds.width * shape.bounds.height * 0.7;
    }
  }

  /// Estimates text width based on content and font size.
  double estimateTextWidth(TextElement text) {
    // Rough estimate: ~0.6 * fontSize per character
    return text.text.length * text.fontSize * 0.6;
  }

  /// Gets default PDF line cap (round).
  int getDefaultLineCap() {
    return 1; // Round cap
  }

  /// Gets default PDF line join (round).
  int getDefaultLineJoin() {
    return 1; // Round join
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

  /// Generates a smooth bezier curve from points.
  List<DrawingPoint> generateBezierCurve(List<DrawingPoint> points) {
    if (points.length <= 2) {
      return points;
    }

    final smoothed = <DrawingPoint>[];
    smoothed.add(points.first);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      // Catmull-Rom spline control points
      final cp1x = p1.x + (p2.x - p0.x) / 6;
      final cp1y = p1.y + (p2.y - p0.y) / 6;
      final cp2x = p2.x - (p3.x - p1.x) / 6;
      final cp2y = p2.y - (p3.y - p1.y) / 6;

      // Sample the curve
      for (double t = 0; t <= 1; t += 0.1) {
        final t2 = t * t;
        final t3 = t2 * t;
        final mt = 1 - t;
        final mt2 = mt * mt;
        final mt3 = mt2 * mt;

        final x = mt3 * p1.x +
            3 * mt2 * t * cp1x +
            3 * mt * t2 * cp2x +
            t3 * p2.x;

        final y = mt3 * p1.y +
            3 * mt2 * t * cp1y +
            3 * mt * t2 * cp2y +
            t3 * p2.y;

        smoothed.add(DrawingPoint(x: x, y: y));
      }
    }

    smoothed.add(points.last);
    return smoothed;
  }

  /// Smooths a stroke path using moving average.
  List<DrawingPoint> smoothStroke(List<DrawingPoint> points) {
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
  List<DrawingPoint> simplifyPath(
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
        math.pow(point.x - lineStart.x, 2) +
            math.pow(point.y - lineStart.y, 2),
      );
    }

    final numerator = ((point.x - lineStart.x) * dy -
            (point.y - lineStart.y) * dx)
        .abs();
    final denominator = math.sqrt(dx * dx + dy * dy);

    return numerator / denominator;
  }

  /// Estimates rendering complexity (0-1, higher is more complex).
  double estimateComplexity(Stroke stroke) {
    final pointCount = stroke.points.length;
    final length = calculateStrokeLength(stroke);

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
      points = simplifyPath(points, tolerance: opts.simplificationTolerance);
    }

    // Smooth stroke if enabled
    if (opts.smoothStrokes && points.length > 2) {
      points = smoothStroke(points);
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
        return 1; // Round
      case PenType.highlighter:
      case PenType.neonHighlighter:
      case PenType.dashedPen:
        return 2; // Square
      case PenType.gelPen:
      case PenType.hardPencil:
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
        return 1; // Round
      case PenType.highlighter:
      case PenType.neonHighlighter:
      case PenType.dashedPen:
        return 0; // Miter
      case PenType.hardPencil:
        return 1; // Round
    }
  }
}
