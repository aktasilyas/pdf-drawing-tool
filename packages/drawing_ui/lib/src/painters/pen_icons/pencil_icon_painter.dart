import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Minimalist pencil icon painter.
///
/// Slim gray pencil with simple design - inspired by iOS style.
/// Drawn with TIP POINTING UP.
class PencilIconPainter extends PenIconPainter {
  const PencilIconPainter({
    super.penColor = const Color(0xFF4A4A4A),
    super.isSelected = false,
    super.size = 56.0,
    super.orientation = PenOrientation.vertical,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;

    // Slim pencil body
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
    // Minimal shadow - very subtle
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

    // Main body - light gray gradient
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.16,
      height: h * 0.58,
    );

    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E8E8),
        Color(0xFFD8D8D8),
        Color(0xFFCCCCCC),
      ],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      Paint()..shader = bodyGradient,
    );

    // Subtle body outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFFBBBBBB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Sharpened tip cone
    final tipPath = Path();
    tipPath.moveTo(w * 0.42, h * 0.23);
    tipPath.lineTo(w * 0.5, h * 0.08);
    tipPath.lineTo(w * 0.58, h * 0.23);
    tipPath.close();

    // Light wood color
    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE0D0C0),
        Color(0xFFD0C0B0),
        Color(0xFFC0B0A0),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Dark graphite point - small triangle
    final graphitePath = Path();
    graphitePath.moveTo(w * 0.47, h * 0.14);
    graphitePath.lineTo(w * 0.5, h * 0.08);
    graphitePath.lineTo(w * 0.53, h * 0.14);
    graphitePath.close();

    canvas.drawPath(graphitePath, Paint()..color = penColor);
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    // No extra details - minimalist
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Single subtle highlight line
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.44, h * 0.26),
      Offset(w * 0.44, h * 0.78),
      highlightPaint,
    );
  }
}
