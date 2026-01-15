import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Dashed pen icon painter.
///
/// Similar to ballpoint pen but with dash pattern indicator
/// on the body to show it draws dashed lines.
class DashedPenIconPainter extends PenIconPainter {
  const DashedPenIconPainter({
    super.penColor = const Color(0xFF1A1A1A),
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
        width: 8,
        height: 40,
      ),
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
    canvas.rotate(-0.4);
    canvas.translate(-centerX, -centerY);

    // Main body - light gray gradient
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 8,
      height: 38,
    );

    final bodyPaint = gradientPaint(
      bodyRect,
      const Color(0xFFF8F8F8),
      const Color(0xFFE8E8E8),
      axis: Axis.horizontal,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      bodyPaint,
    );

    // Body outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      outlinePaint,
    );

    canvas.restore();
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.4);
    canvas.translate(-centerX, -centerY);

    // Metal tip cone
    final tipPath = Path();
    tipPath.moveTo(centerX - 4, centerY + 19);
    tipPath.lineTo(centerX, centerY + 28);
    tipPath.lineTo(centerX + 4, centerY + 19);
    tipPath.close();

    final tipPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFC0C0C0), Color(0xFF909090)],
      ).createShader(Rect.fromLTWH(centerX - 4, centerY + 19, 8, 9));

    canvas.drawPath(tipPath, tipPaint);

    // Ball point
    final ballPaint = Paint()..color = penColor;
    canvas.drawCircle(Offset(centerX, centerY + 27), 1.5, ballPaint);

    canvas.restore();
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.4);
    canvas.translate(-centerX, -centerY);

    // Dash pattern indicator on body (3 short dashes)
    final dashPaint = Paint()
      ..color = penColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(centerX - 2, centerY - 8 + i * 6),
        Offset(centerX + 2, centerY - 8 + i * 6),
        dashPaint,
      );
    }

    // Colored band at top
    final bandRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 16),
      width: 8,
      height: 4,
    );
    final bandPaint = Paint()..color = const Color(0xFF4A9DFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, const Radius.circular(2)),
      bandPaint,
    );

    canvas.restore();
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.4);
    canvas.translate(-centerX, -centerY);

    // Vertical shine
    final shinePaint = highlightPaint(opacity: 0.5);
    canvas.drawLine(
      Offset(centerX - 2, centerY - 14),
      Offset(centerX - 2, centerY + 14),
      shinePaint,
    );

    canvas.restore();
  }
}
