import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Minimalist neon highlighter icon painter.
///
/// Wider body with colorful vertical stripes - inspired by iOS style.
/// Drawn with TIP POINTING UP.
class NeonHighlighterIconPainter extends PenIconPainter {
  const NeonHighlighterIconPainter({
    super.penColor = const Color(0xFFCDDC39), // Lime/neon yellow default
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
        width: w * 0.24,
        height: h * 0.54,
      ),
      const Radius.circular(4),
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
      width: w * 0.24,
      height: h * 0.54,
    );

    // Light body base
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFAFAFA),
        Color(0xFFF2F2F2),
        Color(0xFFEAEAEA),
      ],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..shader = bodyGradient,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFD4D4D4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Colorful vertical stripes on body - like reference image
    final stripeColors = [
      const Color(0xFFCDDC39), // Lime
      const Color(0xFF4DD0E1), // Cyan
      const Color(0xFFFF8A80), // Red/pink
      const Color(0xFFB388FF), // Purple
    ];

    final stripeWidth = w * 0.04;
    final startX = w * 0.35;
    final stripeTop = h * 0.30;
    final stripeBottom = h * 0.74;

    for (var i = 0; i < stripeColors.length; i++) {
      final x = startX + i * (stripeWidth + w * 0.015);
      canvas.drawLine(
        Offset(x, stripeTop),
        Offset(x, stripeBottom),
        Paint()
          ..color = stripeColors[i]
          ..strokeWidth = stripeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Chisel tip
    final tipPath = Path();
    tipPath.moveTo(w * 0.38, h * 0.25);
    tipPath.lineTo(w * 0.42, h * 0.12);
    tipPath.lineTo(w * 0.58, h * 0.12);
    tipPath.lineTo(w * 0.62, h * 0.25);
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

    // Neon colored tip edge
    canvas.drawLine(
      Offset(w * 0.43, h * 0.12),
      Offset(w * 0.57, h * 0.12),
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

    // Light highlight on left edge
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.40, h * 0.28),
      Offset(w * 0.40, h * 0.76),
      highlightPaint,
    );
  }
}
