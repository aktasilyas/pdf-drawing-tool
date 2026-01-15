import 'package:flutter/material.dart';
import 'pencil_icon_painter.dart';

/// Hard pencil (H/2H) icon painter.
///
/// Similar to regular pencil but with cooler gray tones
/// to indicate harder graphite and lighter strokes.
class HardPencilIconPainter extends PencilIconPainter {
  const HardPencilIconPainter({
    super.penColor = const Color(0xFF9E9E9E), // Lighter graphite
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Gray/cool wood body
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 10,
      height: 36,
    );

    final bodyPaint = gradientPaint(
      bodyRect,
      const Color(0xFFE8E4E0), // Light gray
      const Color(0xFFD4D0CC), // Darker gray
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(1)),
      bodyPaint,
    );

    // Subtle grain lines (more muted)
    final grainPaint = Paint()
      ..color = const Color(0xFFC4C0BC)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(centerX + i * 2.5, centerY - 15),
        Offset(centerX + i * 2.5, centerY + 12),
        grainPaint,
      );
    }

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

    // Sharpened wood cone (gray tint)
    final conePath = Path();
    conePath.moveTo(centerX - 5, centerY + 18);
    conePath.lineTo(centerX, centerY + 28);
    conePath.lineTo(centerX + 5, centerY + 18);
    conePath.close();

    final conePaint = Paint()..color = const Color(0xFFC4B8A8);
    canvas.drawPath(conePath, conePaint);

    // Light graphite tip
    final graphitePath = Path();
    graphitePath.moveTo(centerX - 2, centerY + 24);
    graphitePath.lineTo(centerX, centerY + 28);
    graphitePath.lineTo(centerX + 2, centerY + 24);
    graphitePath.close();

    final graphitePaint = Paint()..color = penColor;
    canvas.drawPath(graphitePath, graphitePaint);

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

    // Silver ferrule (instead of gold)
    final ferruleRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 18),
      width: 10,
      height: 4,
    );
    final ferrulePaint = Paint()..color = const Color(0xFFA0A0A0);
    canvas.drawRect(ferruleRect, ferrulePaint);

    // White eraser
    final eraserRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 22),
      width: 8,
      height: 6,
    );
    final eraserPaint = Paint()..color = const Color(0xFFF5F5F5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(eraserRect, const Radius.circular(2)),
      eraserPaint,
    );

    canvas.restore();
  }
}
