import 'dart:ui' show Rect, Offset;
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'drawing_point.dart';
import 'stroke_style.dart';

/// Represents a complete drawing stroke.
///
/// A stroke consists of a series of [DrawingPoint]s that define its path,
/// along with a [StrokeStyle] that determines its visual appearance.
///
/// ## Example
///
/// ```dart
/// final stroke = Stroke(
///   points: [
///     DrawingPoint(position: Offset(0, 0), pressure: 0.5),
///     DrawingPoint(position: Offset(50, 50), pressure: 0.7),
///     DrawingPoint(position: Offset(100, 25), pressure: 0.3),
///   ],
///   style: StrokeStyle.ballpoint(color: Colors.black, thickness: 2.0),
/// );
/// ```
class Stroke extends Equatable {
  /// Creates a new stroke.
  ///
  /// If [id] is not provided, a UUID will be generated.
  Stroke({
    String? id,
    required this.points,
    required this.style,
    this.createdAt,
  }) : id = id ?? const Uuid().v4();

  /// Unique identifier for this stroke.
  final String id;

  /// The sequence of points that make up this stroke.
  final List<DrawingPoint> points;

  /// The visual style of this stroke.
  final StrokeStyle style;

  /// When this stroke was created.
  final DateTime? createdAt;

  /// The cached bounding box of this stroke.
  Rect? _boundingBox;

  /// Returns true if this stroke has no points.
  bool get isEmpty => points.isEmpty;

  /// Returns true if this stroke has at least one point.
  bool get isNotEmpty => points.isNotEmpty;

  /// Returns the number of points in this stroke.
  int get length => points.length;

  /// Returns the first point of this stroke.
  ///
  /// Throws if the stroke is empty.
  DrawingPoint get first => points.first;

  /// Returns the last point of this stroke.
  ///
  /// Throws if the stroke is empty.
  DrawingPoint get last => points.last;

  /// Returns the bounding box that contains all points of this stroke.
  ///
  /// The bounding box is expanded by the nib radius to account for stroke width.
  Rect get boundingBox {
    if (_boundingBox != null) return _boundingBox!;
    if (points.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    // Expand by nib radius
    final padding = style.nibShape.boundingRadius;
    _boundingBox = Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
    return _boundingBox!;
  }

  /// Returns true if this stroke's bounding box intersects with [rect].
  bool intersects(Rect rect) {
    return boundingBox.overlaps(rect);
  }

  /// Returns true if this stroke contains the given [point].
  ///
  /// Uses a distance threshold based on the stroke's nib size.
  bool containsPoint(Offset point, {double tolerance = 0.0}) {
    final threshold = style.nibShape.boundingRadius + tolerance;
    for (final strokePoint in points) {
      if ((strokePoint.position - point).distance <= threshold) {
        return true;
      }
    }
    return false;
  }

  /// Creates a copy of this stroke with the given fields replaced.
  Stroke copyWith({
    String? id,
    List<DrawingPoint>? points,
    StrokeStyle? style,
    DateTime? createdAt,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? List.unmodifiable(this.points),
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Creates a copy with additional points appended.
  Stroke addPoints(List<DrawingPoint> newPoints) {
    return copyWith(points: [...points, ...newPoints]);
  }

  /// Creates a copy with a single point appended.
  Stroke addPoint(DrawingPoint point) {
    return copyWith(points: [...points, point]);
  }

  /// Converts this stroke to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'style': style.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a stroke from a JSON map.
  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id'] as String?,
      points: (json['points'] as List)
          .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, points, style, createdAt];

  @override
  String toString() =>
      'Stroke(id: $id, points: ${points.length}, style: ${style.nibShape.runtimeType})';
}
