import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Classic ballpoint pen icon painter.
///
/// Sleek cylindrical white body with click mechanism,
/// metal clip, and fine ballpoint tip.
class BallpointIconPainter extends PenIconPainter {
  const BallpointIconPainter({
    super.penColor = const Color(0xFF1A1A1A),
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
        width: 8,
        height: 40,
      ),
      const Radius.circular(4),
    ));

    return path;
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.4); // Slight tilt
    canvas.translate(-centerX, -centerY);

    // Main body - white gradient
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 8,
      height: 38,
    );

    final bodyPaint = gradientPaint(
      bodyRect,
      const Color(0xFFFFFFFF),
      const Color(0xFFF0F0F0),
      axis: Axis.horizontal,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      bodyPaint,
    );

    // Body outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      outlinePaint,
    );

    canvas.restore();
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.4);
    canvas.translate(-centerX, -centerY);

    // Metal tip cone
    final tipPath = Path();
    tipPath.moveTo(centerX - 4, centerY + 19);
    tipPath.lineTo(centerX, centerY + 28);
    tipPath.lineTo(centerX + 4, centerY + 19);
    tipPath.close();

    final tipPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
      ).createShader(Rect.fromLTWH(centerX - 4, centerY + 19, 8, 9));

    canvas.drawPath(tipPath, tipPaint);

    // Ball point
    final ballPaint = Paint()..color = penColor;
    canvas.drawCircle(Offset(centerX, centerY + 27), 1.5, ballPaint);

    canvas.restore();
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.4);
    canvas.translate(-centerX, -centerY);

    // Click button at top
    final buttonRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 20),
      width: 6,
      height: 4,
    );
    final buttonPaint = Paint()..color = penColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(1)),
      buttonPaint,
    );

    // Metal clip
    final clipPath = Path();
    clipPath.moveTo(centerX + 4, centerY - 16);
    clipPath.lineTo(centerX + 6, centerY - 16);
    clipPath.lineTo(centerX + 6, centerY + 5);
    clipPath.quadraticBezierTo(
      centerX + 6, centerY + 8,
      centerX + 4, centerY + 8,
    );
    clipPath.close();

    final clipPaint = Paint()
      ..color = const Color(0xFFB0B0B0)
      ..style = PaintingStyle.fill;
    canvas.drawPath(clipPath, clipPaint);

    // Clip highlight
    final clipHighlight = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX + 5, centerY - 14),
      Offset(centerX + 5, centerY + 4),
      clipHighlight,
    );

    // Grip section (textured area)
    final gripPaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var y = centerY + 8; y < centerY + 16; y += 2) {
      canvas.drawLine(
        Offset(centerX - 3, y),
        Offset(centerX + 3, y),
        gripPaint,
      );
    }

    canvas.restore();
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.4);
    canvas.translate(-centerX, -centerY);

    // Vertical shine
    final shinePaint = highlightPaint(opacity: 0.5);
    canvas.drawLine(
      Offset(centerX - 2, centerY - 16),
      Offset(centerX - 2, centerY + 14),
      shinePaint,
    );

    canvas.restore();
  }
}
