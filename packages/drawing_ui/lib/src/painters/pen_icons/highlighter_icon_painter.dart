import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium highlighter marker icon painter.
///
/// Wide rectangular body with semi-transparent colored appearance,
/// chisel tip for broad strokes, colored glow effect.
/// Drawn with TIP POINTING UP (top = chisel tip, bottom = cap).
class HighlighterIconPainter extends PenIconPainter {
  const HighlighterIconPainter({
    super.penColor = const Color(0xFFFFEB3B), // Yellow default
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
        center: Offset(w * 0.5, h * 0.5),
        width: w * 0.24,
        height: h * 0.5,
      ),
      const Radius.circular(4),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    // Colored shadow for glow effect
    final glowPaint = Paint()
      ..color = penColor.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bodyPath = buildBodyPath(rect);

    canvas.save();
    canvas.translate(2, 3);
    canvas.drawPath(bodyPath, glowPaint);

    // Also dark shadow for depth
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.24,
      height: h * 0.5,
    );

    // Semi-transparent colored body with 4-color gradient
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.5), // highlight - more transparent
        penColor.withOpacity(0.75), // mid
        penColor.withOpacity(0.85), // core
        penColor.withOpacity(0.7), // shadow side
      ],
      stops: const [0.0, 0.3, 0.65, 1.0],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..shader = bodyGradient,
    );

    // Cap (at bottom, more opaque)
    final capRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.84),
      width: w * 0.25,
      height: h * 0.1,
    );

    final capGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.7),
        penColor.withOpacity(0.9),
        penColor,
        penColor.withOpacity(0.85),
      ],
    ).createShader(capRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()..shader = capGradient,
    );

    // Cap ring
    final ringRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.78),
      width: w * 0.24,
      height: h * 0.02,
    );
    canvas.drawRect(ringRect, Paint()..color = penColor);
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Chisel tip (at TOP)
    final tipPath = Path();
    tipPath.moveTo(w * 0.38, h * 0.25);
    tipPath.lineTo(w * 0.42, h * 0.10);
    tipPath.lineTo(w * 0.58, h * 0.10);
    tipPath.lineTo(w * 0.62, h * 0.25);
    tipPath.close();

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.8),
        penColor.withOpacity(0.95),
        penColor,
        penColor.withOpacity(0.9),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Tip edge (darker for definition)
    final edgePaint = Paint()
      ..color = penColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawLine(
      Offset(w * 0.42, h * 0.10),
      Offset(w * 0.58, h * 0.10),
      edgePaint,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = createHighlightPaint(opacity: 0.6, width: 2.5);

    // Strong body highlight
    canvas.drawLine(
      Offset(w * 0.40, h * 0.30),
      Offset(w * 0.40, h * 0.72),
      highlightPaint,
    );

    // Cap highlight
    canvas.drawLine(
      Offset(w * 0.41, h * 0.80),
      Offset(w * 0.41, h * 0.88),
      createHighlightPaint(opacity: 0.5, width: 1.5),
    );
  }
}
