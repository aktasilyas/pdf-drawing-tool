import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium neon highlighter icon painter.
///
/// Glowing neon body with bright colors and
/// strong blur/glow effect for that neon look.
/// Drawn with TIP POINTING UP (top = chisel tip, bottom = cap).
class NeonHighlighterIconPainter extends PenIconPainter {
  const NeonHighlighterIconPainter({
    super.penColor = const Color(0xFF76FF03), // Neon green default
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
        height: h * 0.50,
      ),
      const Radius.circular(4),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Strong colored glow effect
    final glowPaint = Paint()
      ..color = penColor.withOpacity(0.4)
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 10);

    final glowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.5),
        width: w * 0.28,
        height: h * 0.56,
      ),
      const Radius.circular(5),
    );

    canvas.drawRRect(glowRect, glowPaint);

    // Secondary glow layer (more concentrated)
    final innerGlowPaint = Paint()
      ..color = penColor.withOpacity(0.3)
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5),
          width: w * 0.25,
          height: h * 0.52,
        ),
        const Radius.circular(4),
      ),
      innerGlowPaint,
    );
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.24,
      height: h * 0.50,
    );

    // Bright neon body with inner glow effect
    final innerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.2),
        radius: 1.2,
        colors: [
          penColor.withOpacity(0.95),
          penColor.withOpacity(0.85),
          penColor.withOpacity(0.75),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      innerPaint,
    );

    // Bright body outline
    final outlinePaint = Paint()
      ..color = penColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      outlinePaint,
    );

    // Cap (at bottom)
    final capRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.82),
      width: w * 0.25,
      height: h * 0.10,
    );

    final capGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.85),
        penColor.withOpacity(0.95),
        penColor,
        penColor.withOpacity(0.9),
      ],
    ).createShader(capRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()..shader = capGradient,
    );

    // Cap ring
    final ringRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.76),
      width: w * 0.24,
      height: h * 0.02,
    );
    canvas.drawRect(ringRect, Paint()..color = penColor);
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Chisel tip with glow (at TOP)
    final tipPath = Path();
    tipPath.moveTo(w * 0.38, h * 0.25);
    tipPath.lineTo(w * 0.42, h * 0.10);
    tipPath.lineTo(w * 0.58, h * 0.10);
    tipPath.lineTo(w * 0.62, h * 0.25);
    tipPath.close();

    // Tip glow
    final tipGlowPaint = Paint()
      ..color = penColor.withOpacity(0.5)
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(tipPath, tipGlowPaint);

    // Solid tip
    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.85),
        penColor.withOpacity(0.95),
        penColor,
        penColor.withOpacity(0.9),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Tip edge
    final edgePaint = Paint()
      ..color = penColor
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

    // Bright white highlight (stronger for neon effect)
    final highlightPaint = createHighlightPaint(opacity: 0.7, width: 2.5);

    canvas.drawLine(
      Offset(w * 0.40, h * 0.30),
      Offset(w * 0.40, h * 0.70),
      highlightPaint,
    );

    // Top shine
    canvas.drawLine(
      Offset(w * 0.41, h * 0.78),
      Offset(w * 0.41, h * 0.86),
      createHighlightPaint(opacity: 0.6, width: 1.5),
    );
  }
}
