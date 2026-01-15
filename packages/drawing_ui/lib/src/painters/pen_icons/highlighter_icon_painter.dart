import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Highlighter marker icon painter.
///
/// Wide rectangular body with semi-transparent colored appearance,
/// chisel tip for broad strokes.
class HighlighterIconPainter extends PenIconPainter {
  const HighlighterIconPainter({
    super.penColor = const Color(0xFFFFEB3B), // Yellow default
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: 14,
        height: 32,
      ),
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
    canvas.rotate(-0.3); // Slight tilt
    canvas.translate(-centerX, -centerY);

    // Wide rectangular body
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 14,
      height: 32,
    );

    // Semi-transparent colored body
    final bodyPaint = Paint()..color = penColor.withAlpha(204); // 0.8 opacity
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      bodyPaint,
    );

    // Body outline for definition
    final outlinePaint = Paint()
      ..color = penColor.withAlpha(255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      outlinePaint,
    );

    // Cap (top part, slightly darker)
    final capRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 14),
      width: 14,
      height: 6,
    );
    final capPaint = Paint()..color = penColor.withAlpha(242); // 0.95 opacity
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(2)),
      capPaint,
    );

    // Cap ring
    final ringRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 10),
      width: 14,
      height: 2,
    );
    final ringPaint = Paint()..color = penColor;
    canvas.drawRect(ringRect, ringPaint);

    canvas.restore();
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.3);
    canvas.translate(-centerX, -centerY);

    // Chisel tip (angled flat tip)
    final tipPath = Path();
    tipPath.moveTo(centerX - 7, centerY + 16);
    tipPath.lineTo(centerX - 4, centerY + 24);
    tipPath.lineTo(centerX + 4, centerY + 24);
    tipPath.lineTo(centerX + 7, centerY + 16);
    tipPath.close();

    final tipPaint = Paint()..color = penColor;
    canvas.drawPath(tipPath, tipPaint);

    // Tip outline
    final tipOutline = Paint()
      ..color = penColor.withAlpha(255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(tipPath, tipOutline);

    canvas.restore();
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.3);
    canvas.translate(-centerX, -centerY);

    // Vertical shine on body
    final shinePaint = highlightPaint(opacity: 0.3);
    canvas.drawLine(
      Offset(centerX - 5, centerY - 12),
      Offset(centerX - 5, centerY + 12),
      shinePaint,
    );

    // Horizontal shine on cap
    canvas.drawLine(
      Offset(centerX - 5, centerY - 15),
      Offset(centerX + 3, centerY - 15),
      shinePaint,
    );

    canvas.restore();
  }
}
