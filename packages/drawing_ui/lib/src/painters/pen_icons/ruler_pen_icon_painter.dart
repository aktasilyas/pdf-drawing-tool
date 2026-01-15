import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Minimalist ruler pen icon painter.
///
/// Simple pencil with ruler indication - inspired by iOS style.
/// Drawn with TIP POINTING UP.
class RulerPenIconPainter extends PenIconPainter {
  const RulerPenIconPainter({
    super.penColor = const Color(0xFF607D8B),
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
        width: w * 0.18,
        height: h * 0.56,
      ),
      const Radius.circular(2),
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
      width: w * 0.18,
      height: h * 0.56,
    );

    // Blue-gray body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFF90A4AE),
        Color(0xFF78909C),
        Color(0xFF607D8B),
      ],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      Paint()..shader = bodyGradient,
    );

    // Ruler markings on left side
    final markPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 0.8;

    for (var i = 0; i < 6; i++) {
      final y = h * 0.30 + i * (h * 0.08);
      final markLength = i % 2 == 0 ? w * 0.06 : w * 0.04;
      canvas.drawLine(
        Offset(w * 0.41, y),
        Offset(w * 0.41 + markLength, y),
        markPaint,
      );
    }
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Pencil tip
    final tipPath = Path();
    tipPath.moveTo(w * 0.41, h * 0.24);
    tipPath.lineTo(w * 0.5, h * 0.08);
    tipPath.lineTo(w * 0.59, h * 0.24);
    tipPath.close();

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE0D4C8),
        Color(0xFFD0C4B8),
        Color(0xFFC0B4A8),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Dark graphite point
    final graphitePath = Path();
    graphitePath.moveTo(w * 0.47, h * 0.15);
    graphitePath.lineTo(w * 0.5, h * 0.08);
    graphitePath.lineTo(w * 0.53, h * 0.15);
    graphitePath.close();

    canvas.drawPath(graphitePath, Paint()..color = penColor);
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    // Minimalist
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Subtle highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.43, h * 0.28),
      Offset(w * 0.43, h * 0.76),
      highlightPaint,
    );
  }
}
