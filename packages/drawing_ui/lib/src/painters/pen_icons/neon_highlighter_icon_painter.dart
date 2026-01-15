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
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.38,
        height: h * 0.48,
      ),
      const Radius.circular(5),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Strong colored glow effect
    final glowPaint = Paint()
      ..color = penColor.withOpacity(0.45)
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 12);

    final glowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.44,
        height: h * 0.54,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(glowRect, glowPaint);

    // Secondary glow layer (more concentrated)
    final innerGlowPaint = Paint()
      ..color = penColor.withOpacity(0.35)
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.52),
          width: w * 0.40,
          height: h * 0.50,
        ),
        const Radius.circular(5),
      ),
      innerGlowPaint,
    );
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.38,
      height: h * 0.48,
    );

    // Bright neon body with inner glow effect
    final innerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.2),
        radius: 1.2,
        colors: [
          penColor.withOpacity(0.96),
          penColor.withOpacity(0.88),
          penColor.withOpacity(0.78),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5)),
      innerPaint,
    );

    // Bright body outline
    final outlinePaint = Paint()
      ..color = penColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5)),
      outlinePaint,
    );

    // Cap (at bottom)
    final capRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.84),
      width: w * 0.40,
      height: h * 0.11,
    );

    final capGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.88),
        penColor.withOpacity(0.96),
        penColor,
        penColor.withOpacity(0.92),
      ],
    ).createShader(capRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(4)),
      Paint()..shader = capGradient,
    );

    // Cap ring
    final ringRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.78),
      width: w * 0.38,
      height: h * 0.025,
    );
    canvas.drawRect(ringRect, Paint()..color = penColor);
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Chisel tip with glow (at TOP) - bigger
    final tipPath = Path();
    tipPath.moveTo(w * 0.31, h * 0.28);
    tipPath.lineTo(w * 0.38, h * 0.10);
    tipPath.lineTo(w * 0.62, h * 0.10);
    tipPath.lineTo(w * 0.69, h * 0.28);
    tipPath.close();

    // Tip glow
    final tipGlowPaint = Paint()
      ..color = penColor.withOpacity(0.55)
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(tipPath, tipGlowPaint);

    // Solid tip
    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.88),
        penColor.withOpacity(0.96),
        penColor,
        penColor.withOpacity(0.92),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Tip edge
    final edgePaint = Paint()
      ..color = penColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(w * 0.38, h * 0.10),
      Offset(w * 0.62, h * 0.10),
      edgePaint,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Bright white highlight (stronger for neon effect)
    final highlightPaint = createHighlightPaint(opacity: 0.75, width: 3.0);

    canvas.drawLine(
      Offset(w * 0.34, h * 0.32),
      Offset(w * 0.34, h * 0.72),
      highlightPaint,
    );

    // Top shine
    canvas.drawLine(
      Offset(w * 0.35, h * 0.80),
      Offset(w * 0.35, h * 0.88),
      createHighlightPaint(opacity: 0.65, width: 2.0),
    );
  }
}
