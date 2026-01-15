import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium ruler pen icon painter.
///
/// Combines a ruler element with a pencil to indicate
/// straight line drawing functionality.
/// Drawn with TIP POINTING UP (top = pencil tip, bottom = ruler end).
class RulerPenIconPainter extends PenIconPainter {
  const RulerPenIconPainter({
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

    // Combined ruler + pencil shape (thicker)
    path.addRect(Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.48,
      height: h * 0.56,
    ));

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

    // Ruler part (left side - thicker)
    final rulerRect = Rect.fromLTWH(
      w * 0.24,
      h * 0.22,
      w * 0.26,
      h * 0.64,
    );

    final rulerGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFF8E1), // highlight (cream)
        Color(0xFFF5DEB3), // light wood
        Color(0xFFE8D4A8), // mid
        Color(0xFFDCC89C), // shadow
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(rulerRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rulerRect, const Radius.circular(2)),
      Paint()..shader = rulerGradient,
    );

    // Ruler markings
    final markPaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 9; i++) {
      final y = h * 0.26 + i * (h * 0.068);
      final markLength = i % 2 == 0 ? w * 0.12 : w * 0.07;
      canvas.drawLine(
        Offset(rulerRect.left, y),
        Offset(rulerRect.left + markLength, y),
        markPaint,
      );
    }

    // Pencil body (right side - thicker)
    final pencilRect = Rect.fromLTWH(
      w * 0.54,
      h * 0.28,
      w * 0.22,
      h * 0.48,
    );

    final pencilGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFF78909C), // highlight
        Color(0xFF607D8B), // light
        Color(0xFF455A64), // core
        Color(0xFF546E7A), // reflected
      ],
      stops: const [0.0, 0.25, 0.7, 1.0],
    ).createShader(pencilRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(pencilRect, const Radius.circular(2)),
      Paint()..shader = pencilGradient,
    );

    // Metal band on pencil top
    final bandRect = Rect.fromLTWH(
      w * 0.54,
      h * 0.28,
      w * 0.22,
      h * 0.05,
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

    // Pencil tip cone (at TOP, right side - bigger)
    final conePath = Path();
    conePath.moveTo(w * 0.54, h * 0.28);
    conePath.lineTo(w * 0.65, h * 0.10);
    conePath.lineTo(w * 0.76, h * 0.28);
    conePath.close();

    final coneGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8D4B8),
        Color(0xFFDEB887),
        Color(0xFFC9A870),
      ],
    ).createShader(conePath.getBounds());

    canvas.drawPath(conePath, Paint()..shader = coneGradient);

    // Graphite tip (bigger)
    final graphitePath = Path();
    graphitePath.moveTo(w * 0.60, h * 0.20);
    graphitePath.lineTo(w * 0.65, h * 0.10);
    graphitePath.lineTo(w * 0.70, h * 0.20);
    graphitePath.close();

    canvas.drawPath(graphitePath, Paint()..color = penColor);
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Straight line indicator on ruler (thicker)
    final linePaint = Paint()
      ..color = penColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.38, h * 0.35),
      Offset(w * 0.38, h * 0.75),
      linePaint,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Ruler edge highlight
    canvas.drawLine(
      Offset(w * 0.27, h * 0.26),
      Offset(w * 0.27, h * 0.82),
      createHighlightPaint(opacity: 0.40, width: 2.0),
    );

    // Pencil highlight
    canvas.drawLine(
      Offset(w * 0.56, h * 0.32),
      Offset(w * 0.56, h * 0.74),
      createHighlightPaint(opacity: 0.45, width: 1.5),
    );
  }
}
