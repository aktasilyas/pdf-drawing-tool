import 'dart:math';

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/element_ids.dart';
import 'package:drawing_core/src/models/shape_type.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

part 'shape_hit_test.dart';
part 'shape_json.dart';

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
      id: ElementIds.next(),
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

    return _hitTestByType(x, y, tolerance);
  }

  /// Immutable copy
  Shape copyWith({
    String? id,
    DrawingPoint? startPoint,
    DrawingPoint? endPoint,
    StrokeStyle? style,
    bool? isFilled,
    int? fillColor,
  }) {
    return Shape(
      id: id ?? this.id,
      type: type,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      style: style ?? this.style,
      isFilled: isFilled ?? this.isFilled,
      fillColor: fillColor ?? this.fillColor,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => _shapeToJson(this);

  /// JSON deserialization
  factory Shape.fromJson(Map<String, dynamic> json) => _shapeFromJson(json);

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
