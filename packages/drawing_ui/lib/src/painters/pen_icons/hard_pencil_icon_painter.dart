import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium hard pencil (H/2H) icon painter.
///
/// Similar to regular pencil but with cooler gray tones
/// to indicate harder graphite and lighter strokes.
/// Drawn with TIP POINTING UP (top = writing tip, bottom = eraser).
class HardPencilIconPainter extends PenIconPainter {
  const HardPencilIconPainter({
    super.penColor = const Color(0xFF9E9E9E), // Lighter graphite
    super.isSelected = false,
    super.size = 56.0,
    super.orientation = PenOrientation.vertical,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;

    // Pencil body - vertical, tip UP (thicker)
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.30,
        height: h * 0.52,
      ),
      const Radius.circular(2),
    ));

    // Tip triangle
    path.moveTo(w * 0.35, h * 0.26);
    path.lineTo(w * 0.5, h * 0.08);
    path.lineTo(w * 0.65, h * 0.26);
    path.close();

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
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.30,
      height: h * 0.52,
    );

    // 4-color gradient for cool gray wood body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFF5F5F5), // highlight edge (white)
        Color(0xFFE8E4E0), // light gray
        Color(0xFFD4D0CC), // core gray
        Color(0xFFBCB8B4), // shadow gray
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      Paint()..shader = bodyGradient,
    );

    // Subtle wood grain lines (more muted)
    final grainPaint = Paint()
      ..color = const Color(0xFFC4C0BC).withOpacity(0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var i = -2; i <= 2; i++) {
      final x = w * 0.5 + i * (w * 0.055);
      canvas.drawLine(
        Offset(x, h * 0.30),
        Offset(x, h * 0.74),
        grainPaint,
      );
    }
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Sharpened wood cone (gray tint, at TOP)
    final conePath = Path();
    conePath.moveTo(w * 0.35, h * 0.26);
    conePath.lineTo(w * 0.5, h * 0.08);
    conePath.lineTo(w * 0.65, h * 0.26);
    conePath.close();

    final coneGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFD8CFC4), // light wood gray
        Color(0xFFC4B8A8), // mid
        Color(0xFFB0A090), // shadow
      ],
    ).createShader(conePath.getBounds());

    canvas.drawPath(conePath, Paint()..shader = coneGradient);

    // Light graphite tip (bigger)
    final graphitePath = Path();
    graphitePath.moveTo(w * 0.44, h * 0.16);
    graphitePath.lineTo(w * 0.5, h * 0.08);
    graphitePath.lineTo(w * 0.56, h * 0.16);
    graphitePath.close();

    final graphiteGradient = LinearGradient(
      colors: [
        penColor.withOpacity(0.7),
        penColor,
        penColor.withOpacity(0.8),
      ],
    ).createShader(graphitePath.getBounds());

    canvas.drawPath(graphitePath, Paint()..shader = graphiteGradient);
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Silver ferrule (instead of gold, at BOTTOM)
    final ferruleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.82),
      width: w * 0.32,
      height: h * 0.07,
    );

    final ferruleGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E8E8), // highlight
        Color(0xFFC0C0C0), // light silver
        Color(0xFF909090), // shadow
        Color(0xFFB0B0B0), // reflected light
      ],
      stops: const [0.0, 0.3, 0.75, 1.0],
    ).createShader(ferruleRect);

    canvas.drawRect(ferruleRect, Paint()..shader = ferruleGradient);

    // White/gray eraser (at BOTTOM)
    final eraserRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.91),
      width: w * 0.28,
      height: h * 0.10,
    );

    final eraserGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFFFFF), // white highlight
        Color(0xFFF5F5F5), // off-white
        Color(0xFFE8E8E8), // light gray
        Color(0xFFF0F0F0), // reflected
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(eraserRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(eraserRect, const Radius.circular(2)),
      Paint()..shader = eraserGradient,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // White highlight on body left edge
    final highlightPaint = createHighlightPaint(opacity: 0.65, width: 2.5);

    canvas.drawLine(
      Offset(w * 0.37, h * 0.30),
      Offset(w * 0.37, h * 0.76),
      highlightPaint,
    );

    // Small highlight on eraser
    canvas.drawLine(
      Offset(w * 0.39, h * 0.87),
      Offset(w * 0.39, h * 0.95),
      createHighlightPaint(opacity: 0.55, width: 1.5),
    );
  }
}
