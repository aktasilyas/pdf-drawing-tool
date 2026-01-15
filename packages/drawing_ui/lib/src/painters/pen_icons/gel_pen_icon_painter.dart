import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Minimalist gel pen icon painter.
///
/// Clean white body with colored tip indicator - inspired by iOS style.
/// Drawn with TIP POINTING UP.
class GelPenIconPainter extends PenIconPainter {
  const GelPenIconPainter({
    super.penColor = const Color(0xFFFF5722), // Orange default
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

    // Rounded tip
    final tipPath = Path();
    tipPath.moveTo(w * 0.42, h * 0.23);
    tipPath.quadraticBezierTo(w * 0.5, h * 0.06, w * 0.58, h * 0.23);
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

    // Colored line at tip edge - like reference image
    canvas.drawLine(
      Offset(w * 0.40, h * 0.22),
      Offset(w * 0.60, h * 0.22),
      Paint()
        ..color = penColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
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
