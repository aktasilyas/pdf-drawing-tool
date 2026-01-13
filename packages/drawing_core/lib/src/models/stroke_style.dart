import 'dart:ui' show Color, BlendMode;
import 'package:equatable/equatable.dart';
import 'nib_shape.dart';

/// Defines the visual appearance of a stroke.
///
/// Combines nib shape, color, and rendering properties to determine
/// how a stroke is displayed on the canvas.
///
/// ## Factory Constructors
///
/// Use the factory constructors for common tool types:
///
/// ```dart
/// final ballpoint = StrokeStyle.ballpoint(color: Colors.blue, thickness: 2.0);
/// final fountain = StrokeStyle.fountain(color: Colors.black, thickness: 3.0);
/// final highlighter = StrokeStyle.highlighter(color: Colors.yellow);
/// ```
class StrokeStyle extends Equatable {
  /// Creates a stroke style with the given properties.
  const StrokeStyle({
    required this.nibShape,
    required this.color,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
    this.pressureSensitivity = 1.0,
    this.tiltSensitivity = 0.0,
    this.minWidth,
    this.maxWidth,
    this.stabilization = 0.0,
  });

  /// Creates a ballpoint pen style with circular nib.
  factory StrokeStyle.ballpoint({
    required Color color,
    required double thickness,
    double pressureSensitivity = 0.5,
    double stabilization = 0.0,
  }) {
    return StrokeStyle(
      nibShape: CircleNib(radius: thickness / 2),
      color: color,
      pressureSensitivity: pressureSensitivity,
      stabilization: stabilization,
    );
  }

  /// Creates a fountain pen style with elliptical nib.
  factory StrokeStyle.fountain({
    required Color color,
    required double thickness,
    double nibAngle = 0.5,
    double pressureSensitivity = 1.0,
    double stabilization = 0.0,
  }) {
    return StrokeStyle(
      nibShape: EllipseNib(
        width: thickness,
        height: thickness * 0.3,
        angle: nibAngle,
      ),
      color: color,
      pressureSensitivity: pressureSensitivity,
      stabilization: stabilization,
    );
  }

  /// Creates a highlighter style with rectangular nib and transparency.
  factory StrokeStyle.highlighter({
    required Color color,
    double thickness = 20.0,
    double opacity = 0.4,
  }) {
    return StrokeStyle(
      nibShape: RectangleNib(
        width: thickness,
        height: thickness * 0.5,
        cornerRadius: 2.0,
      ),
      color: color,
      opacity: opacity,
      blendMode: BlendMode.multiply,
      pressureSensitivity: 0.0,
    );
  }

  /// Creates a pencil style with slight texture effect.
  factory StrokeStyle.pencil({
    required Color color,
    required double thickness,
    double pressureSensitivity = 0.7,
  }) {
    return StrokeStyle(
      nibShape: CircleNib(radius: thickness / 2),
      color: color,
      opacity: 0.9,
      pressureSensitivity: pressureSensitivity,
      stabilization: 0.2,
    );
  }

  /// Creates a brush style with high pressure sensitivity.
  factory StrokeStyle.brush({
    required Color color,
    required double thickness,
    double pressureSensitivity = 1.5,
  }) {
    return StrokeStyle(
      nibShape: CircleNib(radius: thickness / 2),
      color: color,
      pressureSensitivity: pressureSensitivity,
      minWidth: thickness * 0.1,
      maxWidth: thickness * 2.0,
    );
  }

  /// Creates an eraser style using clear blend mode.
  factory StrokeStyle.eraser({
    required double thickness,
  }) {
    return StrokeStyle(
      nibShape: CircleNib(radius: thickness / 2),
      color: const Color(0x00000000),
      blendMode: BlendMode.clear,
      pressureSensitivity: 0.3,
    );
  }

  /// The geometric shape of the nib.
  final NibShape nibShape;

  /// The color of the stroke.
  final Color color;

  /// The opacity of the stroke, from 0.0 (transparent) to 1.0 (opaque).
  final double opacity;

  /// The blend mode used when compositing this stroke.
  final BlendMode blendMode;

  /// How much pressure affects stroke width.
  ///
  /// A value of 0.0 means no pressure effect.
  /// A value of 1.0 means full pressure effect.
  /// Values > 1.0 amplify the pressure effect.
  final double pressureSensitivity;

  /// How much stylus tilt affects stroke rendering.
  ///
  /// A value of 0.0 means tilt is ignored.
  /// Higher values increase the effect of tilt.
  final double tiltSensitivity;

  /// The minimum stroke width when pressure is applied.
  ///
  /// If null, calculated from nib shape.
  final double? minWidth;

  /// The maximum stroke width when full pressure is applied.
  ///
  /// If null, calculated from nib shape.
  final double? maxWidth;

  /// The amount of stroke stabilization (smoothing).
  ///
  /// A value of 0.0 means no stabilization.
  /// A value of 1.0 means maximum stabilization.
  final double stabilization;

  /// Returns the effective stroke width for the given pressure.
  double getWidthForPressure(double pressure) {
    final baseWidth = nibShape.boundingRadius * 2;
    final min = minWidth ?? baseWidth * 0.2;
    final max = maxWidth ?? baseWidth;
    final range = max - min;
    final pressureEffect = pressure * pressureSensitivity;
    return (min + range * pressureEffect).clamp(min, max);
  }

  /// Creates a copy with the given fields replaced.
  StrokeStyle copyWith({
    NibShape? nibShape,
    Color? color,
    double? opacity,
    BlendMode? blendMode,
    double? pressureSensitivity,
    double? tiltSensitivity,
    double? minWidth,
    double? maxWidth,
    double? stabilization,
  }) {
    return StrokeStyle(
      nibShape: nibShape ?? this.nibShape,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      pressureSensitivity: pressureSensitivity ?? this.pressureSensitivity,
      tiltSensitivity: tiltSensitivity ?? this.tiltSensitivity,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      stabilization: stabilization ?? this.stabilization,
    );
  }

  /// Converts this style to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'nibShape': nibShape.toJson(),
      'color': color.value,
      'opacity': opacity,
      'blendMode': blendMode.index,
      'pressureSensitivity': pressureSensitivity,
      'tiltSensitivity': tiltSensitivity,
      if (minWidth != null) 'minWidth': minWidth,
      if (maxWidth != null) 'maxWidth': maxWidth,
      'stabilization': stabilization,
    };
  }

  /// Creates a stroke style from a JSON map.
  factory StrokeStyle.fromJson(Map<String, dynamic> json) {
    return StrokeStyle(
      nibShape: NibShape.fromJson(json['nibShape'] as Map<String, dynamic>),
      color: Color(json['color'] as int),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: BlendMode.values[json['blendMode'] as int? ?? 0],
      pressureSensitivity:
          (json['pressureSensitivity'] as num?)?.toDouble() ?? 1.0,
      tiltSensitivity: (json['tiltSensitivity'] as num?)?.toDouble() ?? 0.0,
      minWidth: (json['minWidth'] as num?)?.toDouble(),
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      stabilization: (json['stabilization'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        nibShape,
        color,
        opacity,
        blendMode,
        pressureSensitivity,
        tiltSensitivity,
        minWidth,
        maxWidth,
        stabilization,
      ];
}
