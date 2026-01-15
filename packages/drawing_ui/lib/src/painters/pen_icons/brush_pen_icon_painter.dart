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
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.14,
        height: h * 0.55,
      ),
      const Radius.circular(2),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final shadowPath = buildBodyPath(rect);

    canvas.save();
    canvas.translate(2.5, 3.0);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.14,
      height: h * 0.55,
    );

    // Slim, elegant dark body
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
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      Paint()..shader = bodyGradient,
    );

    // Metal band (decorative)
    final bandRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.30),
      width: w * 0.15,
      height: h * 0.04,
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

    // Brush bristles (tapered shape, at TOP)
    final bristlePaint = Paint()
      ..color = penColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Metal ferrule holding bristles
    final ferruleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.22),
      width: w * 0.12,
      height: h * 0.04,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(ferruleRect, const Radius.circular(1)),
      Paint()..shader = createMetalGradient(ferruleRect),
    );

    // Bristle bundles - tapered to point
    final baseY = h * 0.20;
    final tipY = h * 0.06;

    for (var i = -2; i <= 2; i++) {
      final startX = w * 0.5 + i * (w * 0.025);
      final endX = w * 0.5 + i * (w * 0.005); // Converges at tip

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
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(startX, baseY),
        Offset(endX, tipY),
        bristleGradient,
      );
    }

    // Central bristle (slightly thicker)
    canvas.drawLine(
      Offset(w * 0.5, baseY),
      Offset(w * 0.5, tipY - h * 0.02),
      bristlePaint..strokeWidth = 1.8,
    );
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Top cap (at BOTTOM)
    final capRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.12,
      height: h * 0.08,
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
      RRect.fromRectAndRadius(capRect, const Radius.circular(2)),
      Paint()..shader = capGradient,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = createHighlightPaint(opacity: 0.35, width: 1.5);

    // Edge highlight on body
    canvas.drawLine(
      Offset(w * 0.44, h * 0.28),
      Offset(w * 0.44, h * 0.76),
      highlightPaint,
    );

    // Metal band highlight
    canvas.drawLine(
      Offset(w * 0.44, h * 0.29),
      Offset(w * 0.44, h * 0.31),
      createHighlightPaint(opacity: 0.5, width: 1.0),
    );
  }
}
