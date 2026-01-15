import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium brush pen icon painter.
///
/// Elegant slim black body with tapered brush bristles tip
/// for artistic calligraphy-like strokes.
/// Drawn with TIP POINTING UP (top = brush bristles, bottom = cap).
class BrushPenIconPainter extends PenIconPainter {
  const BrushPenIconPainter({
    super.penColor = const Color(0xFF424242),
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
        width: w * 0.26,
        height: h * 0.52,
      ),
      const Radius.circular(3),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final shadowPath = buildBodyPath(rect);

    canvas.save();
    canvas.translate(3, 3.5);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.54),
      width: w * 0.26,
      height: h * 0.52,
    );

    // Elegant dark body (thicker)
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFF505050), // highlight
        Color(0xFF3C3C3C), // mid
        Color(0xFF212121), // core
        Color(0xFF2A2A2A), // shadow + reflected
      ],
      stops: const [0.0, 0.25, 0.7, 1.0],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()..shader = bodyGradient,
    );

    // Metal band (decorative)
    final bandRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.34),
      width: w * 0.27,
      height: h * 0.05,
    );

    canvas.drawRect(
      bandRect,
      Paint()..shader = createMetalGradient(bandRect),
    );
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Metal ferrule holding bristles
    final ferruleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.26),
      width: w * 0.22,
      height: h * 0.05,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(ferruleRect, const Radius.circular(1)),
      Paint()..shader = createMetalGradient(ferruleRect),
    );

    // Brush bristles (tapered shape, at TOP)
    final baseY = h * 0.24;
    final tipY = h * 0.06;

    // Bristle bundles - tapered to point (thicker)
    for (var i = -3; i <= 3; i++) {
      final startX = w * 0.5 + i * (w * 0.032);
      final endX = w * 0.5 + i * (w * 0.006); // Converges at tip

      // Bristle gradient effect
      final bristleGradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            penColor,
            penColor.withOpacity(0.8),
          ],
        ).createShader(Rect.fromLTRB(startX - 1, tipY, endX + 1, baseY))
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(startX, baseY),
        Offset(endX, tipY),
        bristleGradient,
      );
    }

    // Central bristle (slightly thicker)
    final bristlePaint = Paint()
      ..color = penColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(w * 0.5, baseY),
      Offset(w * 0.5, tipY - h * 0.02),
      bristlePaint,
    );
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Top cap (at BOTTOM)
    final capRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.22,
      height: h * 0.10,
    );

    final capGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFF505050),
        Color(0xFF3C3C3C),
        Color(0xFF212121),
        Color(0xFF2A2A2A),
      ],
    ).createShader(capRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()..shader = capGradient,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = createHighlightPaint(opacity: 0.4, width: 2.0);

    // Edge highlight on body
    canvas.drawLine(
      Offset(w * 0.38, h * 0.32),
      Offset(w * 0.38, h * 0.76),
      highlightPaint,
    );

    // Metal band highlight
    canvas.drawLine(
      Offset(w * 0.39, h * 0.32),
      Offset(w * 0.39, h * 0.36),
      createHighlightPaint(opacity: 0.55, width: 1.2),
    );
  }
}
