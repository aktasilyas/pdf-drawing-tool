import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Realistic pencil icon painter.
///
/// Classic yellow/wood pencil with eraser, metal ferrule, and graphite tip.
/// Tilted at ~30° angle for natural appearance.
class PencilIconPainter extends PenIconPainter {
  const PencilIconPainter({
    super.penColor = const Color(0xFF2D2D2D),
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
        center: Offset(centerX, centerY),
        width: 10,
        height: 36,
      ),
      const Radius.circular(1),
    ));

    return path;
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5); // ~30° tilt
    canvas.translate(-centerX, -centerY);

    // Wood body gradient (cream/beige)
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 10,
      height: 36,
    );

    final bodyPaint = gradientPaint(
      bodyRect,
      const Color(0xFFF5E6D3),
      const Color(0xFFE8D4BE),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(1)),
      bodyPaint,
    );

    // Wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0xFFD4C4B0)
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

    // Sharpened wood cone
    final conePath = Path();
    conePath.moveTo(centerX - 5, centerY + 18);
    conePath.lineTo(centerX, centerY + 28);
    conePath.lineTo(centerX + 5, centerY + 18);
    conePath.close();

    final conePaint = Paint()..color = const Color(0xFFDEB887);
    canvas.drawPath(conePath, conePaint);

    // Graphite tip
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

    // Metal ferrule
    final ferruleRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 18),
      width: 10,
      height: 4,
    );
    final ferrulePaint = Paint()..color = const Color(0xFFB8860B);
    canvas.drawRect(ferruleRect, ferrulePaint);

    // Pink eraser
    final eraserRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 22),
      width: 8,
      height: 6,
    );
    final eraserPaint = Paint()..color = const Color(0xFFFFB6C1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(eraserRect, const Radius.circular(2)),
      eraserPaint,
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
    final highlightPath = Path();
    highlightPath.moveTo(centerX - 4, centerY - 16);
    highlightPath.lineTo(centerX - 4, centerY + 16);

    canvas.drawPath(highlightPath, highlightPaint(opacity: 0.3));

    canvas.restore();
  }
}
