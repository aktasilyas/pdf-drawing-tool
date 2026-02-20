import 'dart:ui';

import 'package:drawing_ui/src/providers/drawing_providers.dart';

/// Temporary laser stroke data model.
///
/// Unlike regular [Stroke]s, laser strokes are not persisted,
/// not added to history, and fade out after [fadeDuration].
class LaserStroke {
  LaserStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.thickness,
    required this.mode,
    required this.lineStyle,
    required this.completedAt,
    required this.fadeDuration,
  });

  final int id;
  final List<Offset> points;
  final Color color;
  final double thickness;
  final LaserMode mode;
  final LaserLineStyle lineStyle;
  final DateTime completedAt;
  final Duration fadeDuration;

  /// Returns fade progress from 0.0 (fully visible) to 1.0 (fully faded).
  double fadeProgress(DateTime now) {
    final elapsed = now.difference(completedAt);
    if (elapsed <= Duration.zero) return 0.0;
    if (elapsed >= fadeDuration) return 1.0;
    return elapsed.inMicroseconds / fadeDuration.inMicroseconds;
  }

  /// Whether this stroke has completely faded out.
  bool isExpired(DateTime now) => fadeProgress(now) >= 1.0;

  LaserStroke copyWith({List<Offset>? points}) {
    return LaserStroke(
      id: id,
      points: points ?? this.points,
      color: color,
      thickness: thickness,
      mode: mode,
      lineStyle: lineStyle,
      completedAt: completedAt,
      fadeDuration: fadeDuration,
    );
  }
}
