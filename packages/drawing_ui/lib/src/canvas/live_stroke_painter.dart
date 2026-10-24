import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

/// Paints the stroke being drawn from an incrementally updated geometry.
///
/// Built once per canvas; [repaint] (the drawing controller) triggers every
/// frame, so the painter is never rebuilt per pointer event and `paint` only
/// replays the cached paths.
class LiveStrokePainter extends CustomPainter {
  LiveStrokePainter({required this.geometry, required Listenable repaint})
      : super(repaint: repaint);

  /// Geometry of the live stroke, owned by the drawing controller.
  final ActiveStrokeGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) => geometry.paint(canvas);

  @override
  bool shouldRepaint(covariant LiveStrokePainter oldDelegate) =>
      !identical(oldDelegate.geometry, geometry);
}
