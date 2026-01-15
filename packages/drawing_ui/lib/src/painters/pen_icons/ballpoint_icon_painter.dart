import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Minimalist ballpoint pen icon painter.
///
/// Clean white body with small colored tip - inspired by iOS style.
/// Drawn with TIP POINTING UP.
class BallpointIconPainter extends PenIconPainter {
  const BallpointIconPainter({
    super.penColor = const Color(0xFF00BCD4), // Cyan default
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
        center: Offset(w * 0.5, h * 0.50),
        width: w * 0.16,
        height: h * 0.62,
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
      center: Offset(w * 0.5, h * 0.50),
      width: w * 0.16,
      height: h * 0.62,
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

    // Simple conical tip
    final tipPath = Path();
    tipPath.moveTo(w * 0.42, h * 0.19);
    tipPath.lineTo(w * 0.5, h * 0.06);
    tipPath.lineTo(w * 0.58, h * 0.19);
    tipPath.close();

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E8E8),
        Color(0xFFD8D8D8),
        Color(0xFFC8C8C8),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Small colored ball point
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.08),
      w * 0.04,
      Paint()..color = penColor,
    );
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    // Minimalist - no extra details
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
      Offset(w * 0.44, h * 0.22),
      Offset(w * 0.44, h * 0.78),
      highlightPaint,
    );
  }
}
