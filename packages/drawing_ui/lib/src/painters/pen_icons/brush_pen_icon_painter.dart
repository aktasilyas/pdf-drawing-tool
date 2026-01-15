import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Minimalist fountain/brush pen icon painter.
///
/// Clean white body with elegant black nib - inspired by iOS style.
/// Drawn with TIP POINTING UP.
class BrushPenIconPainter extends PenIconPainter {
  const BrushPenIconPainter({
    super.penColor = const Color(0xFF2D2D2D),
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
        center: Offset(w * 0.5, h * 0.54),
        width: w * 0.18,
        height: h * 0.52,
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
      center: Offset(w * 0.5, h * 0.54),
      width: w * 0.18,
      height: h * 0.52,
    );

    // Clean white/light gray body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFF8F8F8),
        Color(0xFFEEEEEE),
        Color(0xFFE4E4E4),
      ],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()..shader = bodyGradient,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFFD0D0D0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Elegant fountain pen nib shape
    final nibPath = Path();
    nibPath.moveTo(w * 0.41, h * 0.28);
    nibPath.quadraticBezierTo(w * 0.41, h * 0.20, w * 0.5, h * 0.06);
    nibPath.quadraticBezierTo(w * 0.59, h * 0.20, w * 0.59, h * 0.28);
    nibPath.close();

    // Dark nib with subtle gradient
    final nibGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.9),
        penColor,
        penColor.withOpacity(0.85),
      ],
    ).createShader(nibPath.getBounds());

    canvas.drawPath(nibPath, Paint()..shader = nibGradient);

    // Small ink hole/slit detail
    canvas.drawLine(
      Offset(w * 0.5, h * 0.12),
      Offset(w * 0.5, h * 0.22),
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
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

    // Body highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.43, h * 0.32),
      Offset(w * 0.43, h * 0.76),
      highlightPaint,
    );

    // Small nib highlight
    canvas.drawLine(
      Offset(w * 0.44, h * 0.14),
      Offset(w * 0.46, h * 0.24),
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
  }
}
