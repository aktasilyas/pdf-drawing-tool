import 'package:equatable/equatable.dart';

/// Outline tuning stored on a stroke so re-tuning presets later never
/// changes existing notes.
///
/// Tapers are in logical pixels, already scaled by the stroke thickness.
/// [StrokeDynamics.none] reproduces the legacy look (round ends).
class StrokeDynamics extends Equatable {
  /// Length over which the stroke start tapers from a point to full width.
  final double taperStart;

  /// Length over which the stroke end tapers from full width to a point.
  final double taperEnd;

  /// Input smoothing amount (0 = raw input, 1 = heavily smoothed).
  final double streamline;

  /// How much drawing speed thins the stroke.
  final double velocityThinning;

  /// Default dynamics: round ends, legacy streamline and velocity thinning.
  static const none = StrokeDynamics();

  const StrokeDynamics({
    this.taperStart = 0.0,
    this.taperEnd = 0.0,
    this.streamline = 0.5,
    this.velocityThinning = 0.2,
  });

  /// Whether this equals the legacy defaults.
  bool get isNone => this == none;

  StrokeDynamics copyWith({
    double? taperStart,
    double? taperEnd,
    double? streamline,
    double? velocityThinning,
  }) {
    return StrokeDynamics(
      taperStart: taperStart ?? this.taperStart,
      taperEnd: taperEnd ?? this.taperEnd,
      streamline: streamline ?? this.streamline,
      velocityThinning: velocityThinning ?? this.velocityThinning,
    );
  }

  Map<String, dynamic> toJson() => {
        'taperStart': taperStart,
        'taperEnd': taperEnd,
        'streamline': streamline,
        'velocityThinning': velocityThinning,
      };

  /// Parses [json]; null or missing fields fall back to [none] values.
  factory StrokeDynamics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;
    double read(String key, double fallback) {
      final v = json[key];
      return v is num ? v.toDouble() : fallback;
    }

    return StrokeDynamics(
      taperStart: read('taperStart', none.taperStart),
      taperEnd: read('taperEnd', none.taperEnd),
      streamline: read('streamline', none.streamline),
      velocityThinning: read('velocityThinning', none.velocityThinning),
    );
  }

  @override
  List<Object?> get props =>
      [taperStart, taperEnd, streamline, velocityThinning];
}
