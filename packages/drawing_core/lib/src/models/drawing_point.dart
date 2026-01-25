import 'package:equatable/equatable.dart';

/// Represents a single point in a drawing stroke.
///
/// A [DrawingPoint] contains the position (x, y), pressure sensitivity,
/// tilt angle, and timestamp of when the point was recorded.
///
/// This class is immutable and uses [Equatable] for value equality.
class DrawingPoint extends Equatable {
  /// The x-coordinate of the point.
  final double x;

  /// The y-coordinate of the point.
  final double y;

  /// The pressure applied at this point (0.0 to 1.0).
  ///
  /// A value of 0.0 means no pressure, 1.0 means full pressure.
  /// Values outside this range are clamped automatically.
  final double pressure;

  /// The tilt angle of the stylus in radians.
  ///
  /// A value of 0.0 means the stylus is perpendicular to the surface.
  final double tilt;

  /// The timestamp when this point was recorded, in milliseconds.
  final int timestamp;

  /// Creates a new [DrawingPoint].
  ///
  /// The [x] and [y] coordinates are required.
  /// [pressure] defaults to 1.0 and is clamped to the range [0.0, 1.0].
  /// [tilt] defaults to 0.0 (perpendicular to surface).
  /// [timestamp] defaults to 0.
  DrawingPoint({
    required this.x,
    required this.y,
    double pressure = 1.0,
    this.tilt = 0.0,
    this.timestamp = 0,
  }) : pressure = pressure.clamp(0.0, 1.0);

  /// Creates a copy of this [DrawingPoint] with the given fields replaced.
  DrawingPoint copyWith({
    double? x,
    double? y,
    double? pressure,
    double? tilt,
    int? timestamp,
  }) {
    return DrawingPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      pressure: pressure ?? this.pressure,
      tilt: tilt ?? this.tilt,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts this [DrawingPoint] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'pressure': pressure,
      'tilt': tilt,
      'timestamp': timestamp,
    };
  }

  /// Creates a [DrawingPoint] from a JSON map.
  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    // Safe number parsing
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }
    
    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      return defaultValue;
    }
    
    return DrawingPoint(
      x: parseDouble(json['x'], 0.0),
      y: parseDouble(json['y'], 0.0),
      pressure: parseDouble(json['pressure'], 1.0),
      tilt: parseDouble(json['tilt'], 0.0),
      timestamp: parseInt(json['timestamp'], 0),
    );
  }

  @override
  List<Object?> get props => [x, y, pressure, tilt, timestamp];

  @override
  String toString() {
    return 'DrawingPoint(x: $x, y: $y, pressure: $pressure, tilt: $tilt, timestamp: $timestamp)';
  }
}
