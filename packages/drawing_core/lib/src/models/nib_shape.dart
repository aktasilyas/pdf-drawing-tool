import 'dart:ui' show Offset;
import 'package:equatable/equatable.dart';

/// Defines the geometric shape of a drawing tool's nib.
///
/// The nib shape determines how strokes are rendered. Different nib types
/// produce different visual characteristics:
///
/// - [CircleNib]: Uniform width strokes (ballpoint pen)
/// - [EllipseNib]: Calligraphic strokes that vary with direction (fountain pen)
/// - [RectangleNib]: Chisel-tip marker strokes (highlighter)
///
/// ## Example
///
/// ```dart
/// final ballpointNib = CircleNib(radius: 2.0);
/// final fountainNib = EllipseNib(width: 4.0, height: 1.5, angle: 0.5);
/// final markerNib = RectangleNib(width: 20.0, height: 8.0);
/// ```
sealed class NibShape extends Equatable {
  const NibShape();

  /// Returns the width of the nib at a given angle.
  ///
  /// The [strokeAngle] is the direction of the stroke in radians,
  /// measured from the positive x-axis.
  double getWidthAtAngle(double strokeAngle);

  /// Returns the bounding radius that encompasses the entire nib shape.
  double get boundingRadius;

  /// Converts this nib shape to a JSON-serializable map.
  Map<String, dynamic> toJson();

  /// Creates a nib shape from a JSON map.
  factory NibShape.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'circle' => CircleNib.fromJson(json),
      'ellipse' => EllipseNib.fromJson(json),
      'rectangle' => RectangleNib.fromJson(json),
      _ => throw ArgumentError('Unknown nib type: $type'),
    };
  }
}

/// A circular nib that produces uniform-width strokes.
///
/// Suitable for ballpoint pens and basic drawing tools.
class CircleNib extends NibShape {
  /// Creates a circular nib with the given radius.
  const CircleNib({required this.radius});

  /// The radius of the circular nib.
  final double radius;

  @override
  double getWidthAtAngle(double strokeAngle) => radius * 2;

  @override
  double get boundingRadius => radius;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'circle',
        'radius': radius,
      };

  factory CircleNib.fromJson(Map<String, dynamic> json) {
    return CircleNib(radius: (json['radius'] as num).toDouble());
  }

  @override
  List<Object?> get props => [radius];

  @override
  String toString() => 'CircleNib(radius: $radius)';
}

/// An elliptical nib that produces calligraphic strokes.
///
/// The stroke width varies based on the direction of movement relative
/// to the nib angle. Suitable for fountain pens and calligraphy tools.
class EllipseNib extends NibShape {
  /// Creates an elliptical nib.
  ///
  /// [width] is the major axis of the ellipse.
  /// [height] is the minor axis of the ellipse.
  /// [angle] is the rotation of the ellipse in radians.
  const EllipseNib({
    required this.width,
    required this.height,
    this.angle = 0.0,
  });

  /// The width (major axis) of the ellipse.
  final double width;

  /// The height (minor axis) of the ellipse.
  final double height;

  /// The rotation angle of the ellipse in radians.
  final double angle;

  @override
  double getWidthAtAngle(double strokeAngle) {
    // TODO: Implement proper ellipse intersection calculation
    // For now, return interpolated value based on angle difference
    final relativeAngle = strokeAngle - angle;
    final cos = relativeAngle.abs() % 3.14159;
    return height + (width - height) * cos;
  }

  @override
  double get boundingRadius => width > height ? width / 2 : height / 2;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ellipse',
        'width': width,
        'height': height,
        'angle': angle,
      };

  factory EllipseNib.fromJson(Map<String, dynamic> json) {
    return EllipseNib(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [width, height, angle];

  @override
  String toString() => 'EllipseNib(w: $width, h: $height, angle: $angle)';
}

/// A rectangular nib that produces chisel-tip strokes.
///
/// Suitable for highlighters and flat-tip markers.
class RectangleNib extends NibShape {
  /// Creates a rectangular nib.
  ///
  /// [width] is the horizontal dimension.
  /// [height] is the vertical dimension.
  /// [cornerRadius] adds rounding to the corners.
  const RectangleNib({
    required this.width,
    required this.height,
    this.cornerRadius = 0.0,
  });

  /// The width of the rectangle.
  final double width;

  /// The height of the rectangle.
  final double height;

  /// The corner radius for rounded rectangles.
  final double cornerRadius;

  @override
  double getWidthAtAngle(double strokeAngle) {
    // Simplified: return diagonal projection
    // TODO: Implement proper rectangle intersection
    return height;
  }

  @override
  double get boundingRadius {
    final halfW = width / 2;
    final halfH = height / 2;
    return Offset(halfW, halfH).distance;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rectangle',
        'width': width,
        'height': height,
        'cornerRadius': cornerRadius,
      };

  factory RectangleNib.fromJson(Map<String, dynamic> json) {
    return RectangleNib(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [width, height, cornerRadius];

  @override
  String toString() =>
      'RectangleNib(w: $width, h: $height, corner: $cornerRadius)';
}
