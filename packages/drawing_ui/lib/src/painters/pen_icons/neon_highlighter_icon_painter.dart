import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'pen_icon_painter.dart';

/// Neon highlighter icon painter.
///
/// Glowing neon body with bright colors and
/// blur/glow effect for that neon look.
class NeonHighlighterIconPainter extends PenIconPainter {
  const NeonHighlighterIconPainter({
    super.penColor = const Color(0xFF76FF03), // Neon green default
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    // Glow effect with colored shadow
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    final glowPaint = Paint()
      ..color = penColor.withAlpha(102) // 0.4 opacity
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 8);

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(centerX, centerY), width: 16, height: 38),
        const Radius.circular(4),
      ),
      glowPaint,
    );

    canvas.restore();
  }

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 14, height: 34),
      const Radius.circular(3),
    ));
    return path;
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Bright neon body
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 14,
      height: 34,
    );

    // Inner glow/brightness
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          penColor.withAlpha(242), // 0.95 opacity
          penColor.withAlpha(179), // 0.7 opacity
        ],
      ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      innerPaint,
    );

    // Body outline
    final outlinePaint = Paint()
      ..color = penColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      outlinePaint,
    );

    // Cap
    final capRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 15),
      width: 14,
      height: 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(2)),
      Paint()..color = penColor,
    );

    // Cap ring
    final ringRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 11),
      width: 14,
      height: 2,
    );
    canvas.drawRect(ringRect, Paint()..color = penColor.withAlpha(200));

    canvas.restore();
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Chisel tip with glow
    final tipPath = Path();
    tipPath.moveTo(centerX - 7, centerY + 17);
    tipPath.lineTo(centerX - 4, centerY + 25);
    tipPath.lineTo(centerX + 4, centerY + 25);
    tipPath.lineTo(centerX + 7, centerY + 17);
    tipPath.close();

    canvas.drawPath(tipPath, Paint()..color = penColor);

    canvas.restore();
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Bright white highlight
    canvas.drawLine(
      Offset(centerX - 5, centerY - 12),
      Offset(centerX - 5, centerY + 8),
      highlightPaint(opacity: 0.5),
    );

    // Top shine
    canvas.drawLine(
      Offset(centerX - 5, centerY - 16),
      Offset(centerX + 3, centerY - 16),
      highlightPaint(opacity: 0.4),
    );

    canvas.restore();
  }
}
