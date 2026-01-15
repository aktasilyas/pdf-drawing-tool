import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Gel pen icon painter.
///
/// Transparent body showing ink reservoir inside,
/// rubber grip section, and smooth gel tip.
class GelPenIconPainter extends PenIconPainter {
  const GelPenIconPainter({
    super.penColor = const Color(0xFF000000),
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 9, height: 38),
      const Radius.circular(4),
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

    // Transparent/semi-transparent body
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 9,
      height: 38,
    );

    // Outer body (transparent white)
    final outerPaint = Paint()
      ..color = Colors.white.withAlpha(230) // 0.9 opacity
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      outerPaint,
    );

    // Body outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      outlinePaint,
    );

    // Inner ink reservoir (colored)
    final inkRect = Rect.fromCenter(
      center: Offset(centerX, centerY + 2),
      width: 4,
      height: 28,
    );
    final inkPaint = Paint()..color = penColor.withAlpha(153); // 0.6 opacity
    canvas.drawRRect(
      RRect.fromRectAndRadius(inkRect, const Radius.circular(2)),
      inkPaint,
    );

    // Rubber grip section
    final gripRect = Rect.fromCenter(
      center: Offset(centerX, centerY + 10),
      width: 10,
      height: 10,
    );
    final gripPaint = Paint()..color = const Color(0xFFE0E0E0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(gripRect, const Radius.circular(2)),
      gripPaint,
    );

    // Grip texture lines
    final gripLinePaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (var y = centerY + 6; y < centerY + 14; y += 2) {
      canvas.drawLine(
        Offset(centerX - 4, y),
        Offset(centerX + 4, y),
        gripLinePaint,
      );
    }

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

    // Conical tip
    final tipPath = Path();
    tipPath.moveTo(centerX - 4, centerY + 19);
    tipPath.lineTo(centerX, centerY + 27);
    tipPath.lineTo(centerX + 4, centerY + 19);
    tipPath.close();

    final tipPaint = Paint()..color = const Color(0xFFE8E8E8);
    canvas.drawPath(tipPath, tipPaint);

    // Colored tip point
    canvas.drawCircle(
      Offset(centerX, centerY + 26),
      1.5,
      Paint()..color = penColor,
    );

    canvas.restore();
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.5);
    canvas.translate(-centerX, -centerY);

    // Cap at top
    final capRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 19),
      width: 8,
      height: 4,
    );
    final capPaint = Paint()..color = penColor.withAlpha(200);
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(2)),
      capPaint,
    );

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

    // Vertical shine on body
    final shinePaint = highlightPaint(opacity: 0.4);
    canvas.drawLine(
      Offset(centerX - 3, centerY - 14),
      Offset(centerX - 3, centerY + 6),
      shinePaint,
    );

    canvas.restore();
  }
}
