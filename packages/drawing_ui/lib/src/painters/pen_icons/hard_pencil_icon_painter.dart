import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Minimalist hard pencil icon painter.
///
/// Slim lighter pencil - inspired by iOS style.
/// Drawn with TIP POINTING UP.
class HardPencilIconPainter extends PenIconPainter {
  const HardPencilIconPainter({
    super.penColor = const Color(0xFF808080),
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
      width: w * 0.16,
      height: h * 0.58,
    );

    // Lighter gray body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFF0F0F0),
        Color(0xFFE0E0E0),
        Color(0xFFD4D4D4),
      ],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      Paint()..shader = bodyGradient,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFFC8C8C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Tip cone
    final tipPath = Path();
    tipPath.moveTo(w * 0.42, h * 0.23);
    tipPath.lineTo(w * 0.5, h * 0.08);
    tipPath.lineTo(w * 0.58, h * 0.23);
    tipPath.close();

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E0D8),
        Color(0xFFD8D0C8),
        Color(0xFFC8C0B8),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Lighter graphite point
    final graphitePath = Path();
    graphitePath.moveTo(w * 0.47, h * 0.14);
    graphitePath.lineTo(w * 0.5, h * 0.08);
    graphitePath.lineTo(w * 0.53, h * 0.14);
    graphitePath.close();

    canvas.drawPath(graphitePath, Paint()..color = penColor);
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
      Offset(w * 0.44, h * 0.26),
      Offset(w * 0.44, h * 0.78),
      highlightPaint,
    );
  }
}
