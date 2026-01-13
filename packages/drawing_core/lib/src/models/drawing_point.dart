import 'dart:ui' show Offset;
import 'package:equatable/equatable.dart';

/// Represents a single point in a drawing stroke.
///
/// Contains position data along with optional pressure and tilt information
/// from stylus input devices.
///
/// ## Example
///
/// ```dart
/// final point = DrawingPoint(
///   position: Offset(100, 200),
///   pressure: 0.5,
///   tilt: 0.1,
///   timestamp: DateTime.now().millisecondsSinceEpoch,
/// );
/// ```
class DrawingPoint extends Equatable {
  /// Creates a new drawing point.
  const DrawingPoint({
    required this.position,
    this.pressure = 1.0,
    this.tilt = 0.0,
    this.timestamp,
  });

  /// Creates a drawing point from x,y coordinates.
  factory DrawingPoint.fromXY(
    double x,
    double y, {
    double pressure = 1.0,
    double tilt = 0.0,
    int? timestamp,
  }) {
    return DrawingPoint(
      position: Offset(x, y),
      pressure: pressure,
      tilt: tilt,
      timestamp: timestamp,
    );
  }

  /// The position of this point in canvas coordinates.
  final Offset position;

  /// The pressure applied at this point, normalized to [0.0, 1.0].
  ///
  /// A value of 1.0 indicates full pressure, 0.0 indicates no pressure.
  /// Defaults to 1.0 for devices without pressure sensitivity.
  final double pressure;

  /// The tilt angle of the stylus at this point, in radians.
  ///
  /// A value of 0.0 indicates the stylus is perpendicular to the screen.
  /// Positive values indicate tilt. Defaults to 0.0.
  final double tilt;

  /// The timestamp when this point was recorded, in milliseconds since epoch.
  ///
  /// Used for velocity calculations and replay functionality.
  final int? timestamp;

  /// The x-coordinate of this point.
  double get x => position.dx;

  /// The y-coordinate of this point.
  double get y => position.dy;

  /// Creates a copy of this point with the given fields replaced.
  DrawingPoint copyWith({
    Offset? position,
    double? pressure,
    double? tilt,
    int? timestamp,
  }) {
    return DrawingPoint(
      position: position ?? this.position,
      pressure: pressure ?? this.pressure,
      tilt: tilt ?? this.tilt,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Linearly interpolates between two points.
  static DrawingPoint lerp(DrawingPoint a, DrawingPoint b, double t) {
    return DrawingPoint(
      position: Offset.lerp(a.position, b.position, t)!,
      pressure: a.pressure + (b.pressure - a.pressure) * t,
      tilt: a.tilt + (b.tilt - a.tilt) * t,
      timestamp: a.timestamp != null && b.timestamp != null
          ? (a.timestamp! + ((b.timestamp! - a.timestamp!) * t)).round()
          : null,
    );
  }

  /// Converts this point to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'pressure': pressure,
      'tilt': tilt,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  /// Creates a point from a JSON map.
  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      pressure: (json['pressure'] as num?)?.toDouble() ?? 1.0,
      tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] as int?,
    );
  }

  @override
  List<Object?> get props => [position, pressure, tilt, timestamp];

  @override
  String toString() =>
      'DrawingPoint(${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)}, p:${pressure.toStringAsFixed(2)})';
}
