import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Minimalist dashed pen icon painter.
///
/// White body with dashed circle around tip - inspired by iOS style.
/// Drawn with TIP POINTING UP.
class DashedPenIconPainter extends PenIconPainter {
  const DashedPenIconPainter({
    super.penColor = const Color(0xFFE91E63), // Pink/red default
    super.isSelected = false,
    super.size = 56.0,
    super.orientation = PenOrientation.vertical,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.16,
        height: h * 0.58,
      ),
      const Radius.circular(3),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowPath = buildBodyPath(rect);

    canvas.save();
    canvas.translate(1.5, 2);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.16,
      height: h * 0.58,
    );

    // Clean white body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFAFAFA),
        Color(0xFFF0F0F0),
        Color(0xFFE8E8E8),
      ],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()..shader = bodyGradient,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFFD4D4D4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Simple rounded tip
    final tipPath = Path();
    tipPath.moveTo(w * 0.42, h * 0.23);
    tipPath.quadraticBezierTo(w * 0.5, h * 0.10, w * 0.58, h * 0.23);
    tipPath.close();

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E8E8),
        Color(0xFFDCDCDC),
        Color(0xFFD0D0D0),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Dashed semicircle around tip - like reference image
    final dashPaint = Paint()
      ..color = penColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = w * 0.5;
    final centerY = h * 0.16;
    final radius = w * 0.14;

    // Draw dashed arc (dots around the tip)
    const dashCount = 8;
    for (var i = 0; i < dashCount; i++) {
      final angle = math.pi + (math.pi * i / (dashCount - 1));
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = penColor);
    }
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    // Minimalist
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.44, h * 0.26),
      Offset(w * 0.44, h * 0.78),
      highlightPaint,
    );
  }
}
