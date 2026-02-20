import 'dart:math';

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/shape_type.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

/// Represents a geometric shape in a drawing.
///
/// A [Shape] is defined by two points (start and end) and can be one of several
/// [ShapeType]s (line, arrow, rectangle, ellipse, etc.).
///
/// Shapes can have stroke styling and optional fill.
///
/// Example:
/// ```dart
/// final shape = Shape.create(
///   type: ShapeType.rectangle,
///   startPoint: DrawingPoint(x: 10, y: 10),
///   endPoint: DrawingPoint(x: 100, y: 100),
///   style: StrokeStyle.solid(color: Colors.blue, thickness: 2.0),
///   isFilled: true,
///   fillColor: Colors.blue.withAlpha(100).value,
/// );
/// ```
class Shape {
  /// Unique identifier for the shape.
  final String id;

  /// The type of this shape (line, rectangle, ellipse, etc).
  final ShapeType type;

  /// The starting point of the shape.
  final DrawingPoint startPoint;

  /// The ending point of the shape.
  final DrawingPoint endPoint;

  /// The stroke style for this shape.
  final StrokeStyle style;

  /// Whether the shape should be filled.
  final bool isFilled;

  /// The fill color in ARGB32 format.
  ///
  /// If null, [style.color] is used for fill.
  final int? fillColor;

  const Shape({
    required this.id,
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.style,
    this.isFilled = false,
    this.fillColor,
  });

  /// Creates a new shape with a generated ID.
  ///
  /// Use this factory to create a new shape when the user completes drawing.
  factory Shape.create({
    required ShapeType type,
    required DrawingPoint startPoint,
    required DrawingPoint endPoint,
    required StrokeStyle style,
    bool isFilled = false,
    int? fillColor,
  }) {
    return Shape(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      startPoint: startPoint,
      endPoint: endPoint,
      style: style,
      isFilled: isFilled,
      fillColor: fillColor,
    );
  }

  /// Bounding box
  BoundingBox get bounds {
    final halfThickness = style.thickness / 2;

    final left = min(startPoint.x, endPoint.x) - halfThickness;
    final top = min(startPoint.y, endPoint.y) - halfThickness;
    final right = max(startPoint.x, endPoint.x) + halfThickness;
    final bottom = max(startPoint.y, endPoint.y) + halfThickness;

    return BoundingBox(left: left, top: top, right: right, bottom: bottom);
  }

  /// Genişlik
  double get width => (endPoint.x - startPoint.x).abs();

  /// Yükseklik
  double get height => (endPoint.y - startPoint.y).abs();

  /// Merkez X koordinatı
  double get centerX => (startPoint.x + endPoint.x) / 2;

  /// Merkez Y koordinatı
  double get centerY => (startPoint.y + endPoint.y) / 2;

  /// Sol kenar (normalized)
  double get left => min(startPoint.x, endPoint.x);

  /// Üst kenar (normalized)
  double get top => min(startPoint.y, endPoint.y);

  /// Sağ kenar (normalized)
  double get right => max(startPoint.x, endPoint.x);

  /// Alt kenar (normalized)
  double get bottom => max(startPoint.y, endPoint.y);

  /// Hit test - nokta shape üzerinde mi?
  bool containsPoint(double x, double y, double tolerance) {
    // Önce bounds check
    final b = bounds;
    if (x < b.left - tolerance ||
        x > b.right + tolerance ||
        y < b.top - tolerance ||
        y > b.bottom + tolerance) {
      return false;
    }

    switch (type) {
      case ShapeType.line:
        return _lineContainsPoint(x, y, tolerance);
      case ShapeType.arrow:
        return _arrowContainsPoint(x, y, tolerance);
      case ShapeType.rectangle:
      case ShapeType.plus:
        return _rectangleContainsPoint(x, y, tolerance);
      case ShapeType.ellipse:
        return _ellipseContainsPoint(x, y, tolerance);
      case ShapeType.triangle:
      case ShapeType.diamond:
      case ShapeType.star:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
        // Polygon shapes use bounds-based hit test for simplicity
        return _polygonContainsPoint(x, y, tolerance);
    }
  }

  bool _polygonContainsPoint(double x, double y, double tolerance) {
    // Simplified hit test using bounding box for complex polygon shapes
    // This provides good UX without complex polygon intersection math
    final effectiveTolerance = tolerance + style.thickness / 2;
    final b = bounds;

    if (isFilled) {
      return x >= b.left - effectiveTolerance &&
          x <= b.right + effectiveTolerance &&
          y >= b.top - effectiveTolerance &&
          y <= b.bottom + effectiveTolerance;
    } else {
      // For stroked polygons, check if near any edge (approximate)
      final cx = centerX;
      final cy = centerY;
      final hw = width / 2;
      final hh = height / 2;

      // Check distance from center as approximation
      final dx = (x - cx).abs();
      final dy = (y - cy).abs();

      // If within tolerance of the polygon boundary
      final normalizedDist = (dx / hw + dy / hh) / 2;
      return normalizedDist >= 0.7 - effectiveTolerance / min(hw, hh) &&
          normalizedDist <= 1.0 + effectiveTolerance / min(hw, hh);
    }
  }

  bool _lineContainsPoint(double x, double y, double tolerance) {
    final effectiveTolerance = tolerance + style.thickness / 2;
    return _pointToLineDistance(
          x,
          y,
          startPoint.x,
          startPoint.y,
          endPoint.x,
          endPoint.y,
        ) <=
        effectiveTolerance;
  }

  bool _arrowContainsPoint(double x, double y, double tolerance) {
    // Ana çizgi kontrolü
    if (_lineContainsPoint(x, y, tolerance)) return true;

    // Ok başı kontrolü (basitleştirilmiş - bounds check yeterli)
    final arrowHeadSize = style.thickness * 4;
    final dx = endPoint.x - startPoint.x;
    final dy = endPoint.y - startPoint.y;
    final length = sqrt(dx * dx + dy * dy);

    if (length < 1) return false;

    // Ok başı bölgesinde mi?
    final distToEnd = sqrt(pow(x - endPoint.x, 2) + pow(y - endPoint.y, 2));
    return distToEnd <= arrowHeadSize + tolerance;
  }

  bool _rectangleContainsPoint(double x, double y, double tolerance) {
    final effectiveTolerance = tolerance + style.thickness / 2;
    final b = bounds;

    if (isFilled) {
      // İçi dolu - bounds içinde mi?
      return x >= b.left - effectiveTolerance &&
          x <= b.right + effectiveTolerance &&
          y >= b.top - effectiveTolerance &&
          y <= b.bottom + effectiveTolerance;
    } else {
      // Sadece kenarlar
      final onLeft = (x - b.left).abs() <= effectiveTolerance &&
          y >= b.top &&
          y <= b.bottom;
      final onRight = (x - b.right).abs() <= effectiveTolerance &&
          y >= b.top &&
          y <= b.bottom;
      final onTop = (y - b.top).abs() <= effectiveTolerance &&
          x >= b.left &&
          x <= b.right;
      final onBottom = (y - b.bottom).abs() <= effectiveTolerance &&
          x >= b.left &&
          x <= b.right;

      return onLeft || onRight || onTop || onBottom;
    }
  }

  bool _ellipseContainsPoint(double x, double y, double tolerance) {
    final cx = centerX;
    final cy = centerY;
    final rx = width / 2;
    final ry = height / 2;

    if (rx < 1 || ry < 1) return false;

    // Normalize edilmiş mesafe
    final normalizedDist = pow((x - cx) / rx, 2) + pow((y - cy) / ry, 2);

    if (isFilled) {
      return normalizedDist <= 1.0 + tolerance / min(rx, ry);
    } else {
      // Kenar üzerinde mi?
      final innerRx = rx - style.thickness / 2;
      final innerRy = ry - style.thickness / 2;
      final outerRx = rx + style.thickness / 2;
      final outerRy = ry + style.thickness / 2;

      final innerDist = innerRx > 0 && innerRy > 0
          ? pow((x - cx) / innerRx, 2) + pow((y - cy) / innerRy, 2)
          : 0.0;
      final outerDist =
          pow((x - cx) / outerRx, 2) + pow((y - cy) / outerRy, 2);

      return outerDist <= 1.0 + tolerance / min(rx, ry) &&
          innerDist >= 1.0 - tolerance / min(rx, ry);
    }
  }

  double _pointToLineDistance(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return sqrt(pow(px - x1, 2) + pow(py - y1, 2));
    }

    final t = max(
        0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)));

    final nearestX = x1 + t * dx;
    final nearestY = y1 + t * dy;

    return sqrt(pow(px - nearestX, 2) + pow(py - nearestY, 2));
  }

  /// Immutable copy
  Shape copyWith({
    DrawingPoint? startPoint,
    DrawingPoint? endPoint,
    StrokeStyle? style,
    bool? isFilled,
    int? fillColor,
  }) {
    return Shape(
      id: id,
      type: type,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      style: style ?? this.style,
      isFilled: isFilled ?? this.isFilled,
      fillColor: fillColor ?? this.fillColor,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'startPoint': startPoint.toJson(),
        'endPoint': endPoint.toJson(),
        'style': style.toJson(),
        'isFilled': isFilled,
        'fillColor': fillColor,
      };

  /// JSON deserialization
  factory Shape.fromJson(Map<String, dynamic> json) {
    // Safe int parsing
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }
    
    return Shape(
      id: json['id'] as String,
      type: ShapeType.values.byName(json['type'] as String),
      startPoint:
          DrawingPoint.fromJson(json['startPoint'] as Map<String, dynamic>),
      endPoint:
          DrawingPoint.fromJson(json['endPoint'] as Map<String, dynamic>),
      style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
      isFilled: (json['isFilled'] as bool?) ?? false,
      fillColor: parseInt(json['fillColor']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Shape) return false;
    return other.id == id &&
        other.type == type &&
        other.startPoint == startPoint &&
        other.endPoint == endPoint &&
        other.style == style &&
        other.isFilled == isFilled &&
        other.fillColor == fillColor;
  }

  @override
  int get hashCode => Object.hash(id, type, isFilled);
}
