import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Ruler pen icon painter.
///
/// Combines a ruler element with a pencil to indicate
/// straight line drawing functionality.
class RulerPenIconPainter extends PenIconPainter {
  const RulerPenIconPainter({
    super.penColor = const Color(0xFF424242),
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;
    // Combined ruler + pencil shape
    path.addRect(Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 20,
      height: 36,
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

    // Ruler part (left side)
    final rulerRect = Rect.fromLTWH(
      centerX - 12,
      centerY - 18,
      10,
      36,
    );

    final rulerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFF5DEB3), Color(0xFFE8D4A8)],
      ).createShader(rulerRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rulerRect, const Radius.circular(1)),
      rulerPaint,
    );

    // Ruler markings
    final markPaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 7; i++) {
      final y = centerY - 14 + i * 5;
      final markLength = i % 2 == 0 ? 4.0 : 2.5;
      canvas.drawLine(
        Offset(centerX - 12, y),
        Offset(centerX - 12 + markLength, y),
        markPaint,
      );
    }

    // Pencil body (right side)
    final pencilRect = Rect.fromLTWH(
      centerX - 1,
      centerY - 16,
      8,
      28,
    );

    final pencilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF607D8B), Color(0xFF455A64)],
      ).createShader(pencilRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(pencilRect, const Radius.circular(1)),
      pencilPaint,
    );

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

    // Pencil tip cone
    final conePath = Path();
    conePath.moveTo(centerX - 1, centerY + 12);
    conePath.lineTo(centerX + 3, centerY + 20);
    conePath.lineTo(centerX + 7, centerY + 12);
    conePath.close();

    canvas.drawPath(conePath, Paint()..color = const Color(0xFFDEB887));

    // Graphite tip
    final graphitePath = Path();
    graphitePath.moveTo(centerX + 1, centerY + 17);
    graphitePath.lineTo(centerX + 3, centerY + 21);
    graphitePath.lineTo(centerX + 5, centerY + 17);
    graphitePath.close();

    canvas.drawPath(graphitePath, Paint()..color = penColor);

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

    // Straight line indicator on ruler
    final linePaint = Paint()
      ..color = penColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - 7, centerY - 8),
      Offset(centerX - 7, centerY + 10),
      linePaint,
    );

    // Metal band on pencil
    final bandRect = Rect.fromLTWH(
      centerX - 1,
      centerY - 16,
      8,
      3,
    );
    canvas.drawRect(bandRect, Paint()..color = const Color(0xFF9E9E9E));

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

    // Ruler edge highlight
    canvas.drawLine(
      Offset(centerX - 11, centerY - 16),
      Offset(centerX - 11, centerY + 14),
      highlightPaint(opacity: 0.25),
    );

    // Pencil highlight
    canvas.drawLine(
      Offset(centerX, centerY - 14),
      Offset(centerX, centerY + 8),
      highlightPaint(opacity: 0.3),
    );

    canvas.restore();
  }
}
