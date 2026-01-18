import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart' as core;

/// Painter for pixel eraser preview - shows affected segments.
class PixelEraserPreviewPainter extends CustomPainter {
  const PixelEraserPreviewPainter({
    required this.strokes,
    required this.affectedSegments,
  });

  final List<core.Stroke> strokes;
  final Map<String, List<int>> affectedSegments;

  @override
  void paint(Canvas canvas, Size size) {
    if (affectedSegments.isEmpty) return;

    // Paint for affected segments (semi-transparent red)
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw affected segments
    for (final stroke in strokes) {
      final segments = affectedSegments[stroke.id];
      if (segments == null || segments.isEmpty) continue;

      final points = stroke.points;
      if (points.length < 2) continue;

      // Draw each affected segment
      for (final segmentIndex in segments) {
        if (segmentIndex < 0 || segmentIndex >= points.length - 1) continue;

        final p1 = points[segmentIndex];
        final p2 = points[segmentIndex + 1];

        canvas.drawLine(
          Offset(p1.x, p1.y),
          Offset(p2.x, p2.y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelEraserPreviewPainter oldDelegate) {
    return affectedSegments != oldDelegate.affectedSegments ||
        strokes != oldDelegate.strokes;
  }
}
