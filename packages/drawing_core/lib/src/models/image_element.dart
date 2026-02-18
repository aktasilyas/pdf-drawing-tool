import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';

/// Represents an image element in a drawing.
///
/// An [ImageElement] references an image file positioned at a specific location
/// with size and rotation properties.
class ImageElement {
  /// Unique identifier for the image element.
  final String id;

  /// Path to the image file on disk.
  final String filePath;

  /// X-coordinate of the image position (top-left corner).
  final double x;

  /// Y-coordinate of the image position (top-left corner).
  final double y;

  /// Width of the image on canvas.
  final double width;

  /// Height of the image on canvas.
  final double height;

  /// Rotation angle in radians.
  final double rotation;

  const ImageElement({
    required this.id,
    required this.filePath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
  });

  /// Creates a new image element with a generated ID.
  factory ImageElement.create({
    required String filePath,
    required double x,
    required double y,
    required double width,
    required double height,
    double rotation = 0.0,
  }) {
    return ImageElement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      filePath: filePath,
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
    );
  }

  /// Bounding box for the image element.
  BoundingBox get bounds {
    if (rotation == 0.0) {
      return BoundingBox(left: x, top: y, right: x + width, bottom: y + height);
    }
    // Rotated bounding box
    final cx = x + width / 2;
    final cy = y + height / 2;
    final corners = [
      _rotatePoint(x, y, cx, cy),
      _rotatePoint(x + width, y, cx, cy),
      _rotatePoint(x + width, y + height, cx, cy),
      _rotatePoint(x, y + height, cx, cy),
    ];
    double minX = corners[0].dx, maxX = corners[0].dx;
    double minY = corners[0].dy, maxY = corners[0].dy;
    for (final c in corners) {
      if (c.dx < minX) minX = c.dx;
      if (c.dx > maxX) maxX = c.dx;
      if (c.dy < minY) minY = c.dy;
      if (c.dy > maxY) maxY = c.dy;
    }
    return BoundingBox(left: minX, top: minY, right: maxX, bottom: maxY);
  }

  _Offset _rotatePoint(double px, double py, double cx, double cy) {
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);
    final dx = px - cx;
    final dy = py - cy;
    return _Offset(cx + dx * cosR - dy * sinR, cy + dx * sinR + dy * cosR);
  }

  /// Hit test - is the point inside the image bounds?
  bool containsPoint(double px, double py, double tolerance) {
    final b = bounds;
    return px >= b.left - tolerance &&
        px <= b.right + tolerance &&
        py >= b.top - tolerance &&
        py <= b.bottom + tolerance;
  }

  /// Immutable copy.
  ImageElement copyWith({
    String? filePath,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return ImageElement(
      id: id,
      filePath: filePath ?? this.filePath,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }

  /// JSON serialization.
  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
      };

  factory ImageElement.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }

    return ImageElement(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      x: parseDouble(json['x'], 0.0),
      y: parseDouble(json['y'], 0.0),
      width: parseDouble(json['width'], 200.0),
      height: parseDouble(json['height'], 200.0),
      rotation: parseDouble(json['rotation'], 0.0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImageElement) return false;
    return other.id == id &&
        other.filePath == filePath &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(id, filePath, x, y, width, height);
}

/// Minimal offset class to avoid Flutter dependency.
class _Offset {
  final double dx;
  final double dy;
  const _Offset(this.dx, this.dy);
}
