import 'package:equatable/equatable.dart';

/// Represents an axis-aligned bounding box.
///
/// A [BoundingBox] is defined by its left, top, right, and bottom edges.
/// This class is immutable and uses [Equatable] for value equality.
class BoundingBox extends Equatable {
  /// The left edge of the bounding box.
  final double left;

  /// The top edge of the bounding box.
  final double top;

  /// The right edge of the bounding box.
  final double right;

  /// The bottom edge of the bounding box.
  final double bottom;

  /// Creates a new [BoundingBox].
  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Creates a [BoundingBox] from a single point.
  factory BoundingBox.fromPoint(double x, double y) {
    return BoundingBox(left: x, top: y, right: x, bottom: y);
  }

  /// Creates an empty [BoundingBox] at origin.
  factory BoundingBox.zero() {
    return const BoundingBox(left: 0, top: 0, right: 0, bottom: 0);
  }

  /// The width of the bounding box.
  double get width => right - left;

  /// The height of the bounding box.
  double get height => bottom - top;

  /// The center X coordinate.
  double get centerX => (left + right) / 2;

  /// The center Y coordinate.
  double get centerY => (top + bottom) / 2;

  /// Whether the bounding box has zero area.
  bool get isEmpty => width == 0 && height == 0;

  /// Returns true if the point (x, y) is inside the bounding box.
  bool contains(double x, double y) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  /// Returns a new [BoundingBox] expanded to include the point (x, y).
  BoundingBox expandTo(double x, double y) {
    return BoundingBox(
      left: x < left ? x : left,
      top: y < top ? y : top,
      right: x > right ? x : right,
      bottom: y > bottom ? y : bottom,
    );
  }

  /// Returns a new [BoundingBox] that includes both this box and [other].
  BoundingBox union(BoundingBox other) {
    return BoundingBox(
      left: other.left < left ? other.left : left,
      top: other.top < top ? other.top : top,
      right: other.right > right ? other.right : right,
      bottom: other.bottom > bottom ? other.bottom : bottom,
    );
  }

  /// Returns a new [BoundingBox] inflated by [delta] on all sides.
  BoundingBox inflate(double delta) {
    return BoundingBox(
      left: left - delta,
      top: top - delta,
      right: right + delta,
      bottom: bottom + delta,
    );
  }

  /// Creates a copy of this [BoundingBox] with the given fields replaced.
  BoundingBox copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return BoundingBox(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  /// Converts this [BoundingBox] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  /// Creates a [BoundingBox] from a JSON map.
  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [left, top, right, bottom];

  @override
  String toString() {
    return 'BoundingBox(left: $left, top: $top, right: $right, bottom: $bottom)';
  }
}
