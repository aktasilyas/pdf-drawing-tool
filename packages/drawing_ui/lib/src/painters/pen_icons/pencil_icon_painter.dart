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

    // Horizontal pencil (no rotation)
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 38,
      height: 8,
    );

    // Refined wood gradient - more realistic
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF5E6D3).withAlpha(255),
          const Color(0xFFE8D4BE),
          const Color(0xFFD4C4B0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)),
      bodyPaint,
    );

    // Subtle wood grain (horizontal lines)
    final grainPaint = Paint()
      ..color = const Color(0xFFD4C4B0).withAlpha(60)
      ..strokeWidth = 0.3
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 3; i++) {
      final x = centerX - 14 + i * 6;
      canvas.drawLine(
        Offset(x, centerY - 3),
        Offset(x, centerY + 3),
        grainPaint,
      );
    }
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    // Sharpened wood cone (horizontal, pointing right)
    final conePath = Path();
    conePath.moveTo(centerX + 14, centerY - 4);
    conePath.lineTo(centerX + 24, centerY);
    conePath.lineTo(centerX + 14, centerY + 4);
    conePath.close();

    final conePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFDEB887),
          const Color(0xFFC9A870),
        ],
      ).createShader(conePath.getBounds());
    canvas.drawPath(conePath, conePaint);

    // Graphite tip (smaller, more refined)
    final graphitePath = Path();
    graphitePath.moveTo(centerX + 20, centerY - 1.5);
    graphitePath.lineTo(centerX + 26, centerY);
    graphitePath.lineTo(centerX + 20, centerY + 1.5);
    graphitePath.close();

    final graphitePaint = Paint()..color = penColor;
    canvas.drawPath(graphitePath, graphitePaint);
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    // Metal ferrule (left side, horizontal)
    final ferruleRect = Rect.fromCenter(
      center: Offset(centerX - 15, centerY),
      width: 3,
      height: 8,
    );
    final ferrulePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFB8860B),
          const Color(0xFFD4AF37),
        ],
      ).createShader(ferruleRect);
    canvas.drawRect(ferruleRect, ferrulePaint);

    // Pink eraser (left end)
    final eraserRect = Rect.fromCenter(
      center: Offset(centerX - 20, centerY),
      width: 6,
      height: 7,
    );
    final eraserPaint = Paint()..color = const Color(0xFFFFB6C1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(eraserRect, const Radius.circular(2)),
      eraserPaint,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    // Top edge highlight (horizontal pencil)
    canvas.drawLine(
      Offset(centerX - 16, centerY - 3),
      Offset(centerX + 12, centerY - 3),
      highlightPaint(opacity: 0.4),
    );
  }
}
