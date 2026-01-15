import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Brush pen icon painter.
///
/// Elegant slim body with tapered brush bristles tip
/// for artistic calligraphy-like strokes.
class BrushPenIconPainter extends PenIconPainter {
  const BrushPenIconPainter({
    super.penColor = const Color(0xFF424242),
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(centerX, centerY - 4), width: 8, height: 32),
      const Radius.circular(2),
    ));
    return path;
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Slim, elegant black body
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 4),
      width: 8,
      height: 32,
    );

    final bodyPaint = gradientPaint(
      bodyRect,
      const Color(0xFF616161),
      const Color(0xFF212121),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      bodyPaint,
    );

    // Metal band
    final bandRect = Rect.fromCenter(
      center: Offset(centerX, centerY + 8),
      width: 9,
      height: 4,
    );
    canvas.drawRect(bandRect, Paint()..color = const Color(0xFF9E9E9E));

    canvas.restore();
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Brush bristles (tapered shape)
    final bristlePaint = Paint()
      ..color = penColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Bristle bundles - tapered to point
    final baseY = centerY + 12;
    final tipY = centerY + 26;

    for (var i = -2; i <= 2; i++) {
      final startX = centerX + i * 1.5;
      final endX = centerX + i * 0.3; // Converges at tip
      canvas.drawLine(
        Offset(startX, baseY),
        Offset(endX, tipY),
        bristlePaint,
      );
    }

    canvas.restore();
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Top cap
    final capRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 18),
      width: 6,
      height: 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF424242),
    );

    canvas.restore();
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Edge highlight
    canvas.drawLine(
      Offset(centerX - 3, centerY - 16),
      Offset(centerX - 3, centerY + 6),
      highlightPaint(opacity: 0.3),
    );

    canvas.restore();
  }
}
