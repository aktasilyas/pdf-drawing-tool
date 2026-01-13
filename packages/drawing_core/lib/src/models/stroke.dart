import 'package:equatable/equatable.dart';

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

/// Represents a single stroke in a drawing.
///
/// A [Stroke] consists of a list of [DrawingPoint]s and a [StrokeStyle].
/// The stroke is immutable - adding points returns a new [Stroke] instance.
///
/// This class uses [Equatable] for value equality.
class Stroke extends Equatable {
  /// Unique identifier for the stroke.
  final String id;

  /// The points that make up this stroke.
  ///
  /// This list is unmodifiable.
  final List<DrawingPoint> points;

  /// The visual style of this stroke.
  final StrokeStyle style;

  /// When this stroke was created.
  final DateTime createdAt;

  /// Creates a new [Stroke].
  ///
  /// The [points] list is wrapped in [List.unmodifiable] to ensure immutability.
  Stroke({
    required this.id,
    required List<DrawingPoint> points,
    required this.style,
    required this.createdAt,
  }) : points = List.unmodifiable(points);

  /// Creates a new stroke with a generated ID.
  ///
  /// Use this factory to create a new stroke when starting to draw.
  factory Stroke.create({
    required StrokeStyle style,
    List<DrawingPoint>? points,
  }) {
    return Stroke(
      id: _generateId(),
      points: points ?? const [],
      style: style,
      createdAt: DateTime.now(),
    );
  }

  /// Generates a unique ID based on the current timestamp.
  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  /// Whether this stroke has no points.
  bool get isEmpty => points.isEmpty;

  /// Whether this stroke has at least one point.
  bool get isNotEmpty => points.isNotEmpty;

  /// The number of points in this stroke.
  int get pointCount => points.length;

  /// The first point of this stroke, or null if empty.
  DrawingPoint? get firstPoint => isEmpty ? null : points.first;

  /// The last point of this stroke, or null if empty.
  DrawingPoint? get lastPoint => isEmpty ? null : points.last;

  /// Calculates and returns the bounding box of this stroke.
  ///
  /// Returns null if the stroke is empty.
  BoundingBox? get bounds {
    if (isEmpty) return null;

    double minX = points.first.x;
    double minY = points.first.y;
    double maxX = points.first.x;
    double maxY = points.first.y;

    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    return BoundingBox(
      left: minX,
      top: minY,
      right: maxX,
      bottom: maxY,
    );
  }

  /// Returns a new [Stroke] with the given point added.
  ///
  /// The original stroke is not modified.
  Stroke addPoint(DrawingPoint point) {
    return Stroke(
      id: id,
      points: [...points, point],
      style: style,
      createdAt: createdAt,
    );
  }

  /// Returns a new [Stroke] with the given points added.
  ///
  /// The original stroke is not modified.
  Stroke addPoints(List<DrawingPoint> newPoints) {
    return Stroke(
      id: id,
      points: [...points, ...newPoints],
      style: style,
      createdAt: createdAt,
    );
  }

  /// Checks if a point is within tolerance distance of this stroke.
  ///
  /// This is a stub implementation for Phase 2.
  /// Full implementation will be done in Phase 3.
  ///
  /// Returns false (stub).
  bool containsPoint(double x, double y, {double tolerance = 5.0}) {
    // TODO: Implement in Phase 3
    // Will check if (x, y) is within tolerance distance of any segment
    return false;
  }

  /// Creates a copy of this [Stroke] with the given fields replaced.
  Stroke copyWith({
    String? id,
    List<DrawingPoint>? points,
    StrokeStyle? style,
    DateTime? createdAt,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this [Stroke] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'style': style.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a [Stroke] from a JSON map.
  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id'] as String,
      points: (json['points'] as List)
          .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, points, style, createdAt];

  @override
  String toString() {
    return 'Stroke(id: $id, pointCount: $pointCount, style: ${style.toString()})';
  }
}
