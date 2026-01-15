import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium gel pen icon painter.
///
/// Transparent body showing ink reservoir inside,
/// rubber grip section, and smooth gel tip.
/// Drawn with TIP POINTING UP (top = gel tip, bottom = colored cap).
class GelPenIconPainter extends PenIconPainter {
  const GelPenIconPainter({
    super.penColor = const Color(0xFF000000),
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
        width: w * 0.28,
        height: h * 0.56,
      ),
      const Radius.circular(5),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
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
      width: w * 0.28,
      height: h * 0.56,
    );

    // Transparent/semi-transparent outer body
    final outerGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFFFFF), // highlight
        Color(0xFFFAFAFA),
        Color(0xFFF0F0F0),
        Color(0xFFF5F5F5), // reflected
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5)),
      Paint()..shader = outerGradient,
    );

    // Body outline for definition
    final outlinePaint = Paint()
      ..color = const Color(0xFFD8D8D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5)),
      outlinePaint,
    );

    // Inner ink reservoir (colored, visible through transparent body)
    final inkRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.50),
      width: w * 0.12,
      height: h * 0.42,
    );

    final inkGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.45),
        penColor.withOpacity(0.65),
        penColor.withOpacity(0.55),
      ],
    ).createShader(inkRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(inkRect, const Radius.circular(3)),
      Paint()..shader = inkGradient,
    );

    // Rubber grip section (at lower part of body)
    final gripRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.32),
      width: w * 0.29,
      height: h * 0.14,
    );

    final gripGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E8E8),
        Color(0xFFD0D0D0),
        Color(0xFFB0B0B0),
        Color(0xFFC8C8C8),
      ],
    ).createShader(gripRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(gripRect, const Radius.circular(3)),
      Paint()..shader = gripGradient,
    );

    // Grip texture lines
    final gripLinePaint = Paint()
      ..color = const Color(0xFF909090).withOpacity(0.55)
      ..strokeWidth = 0.7;

    for (var i = 0; i < 4; i++) {
      final y = gripRect.top + 3.5 + i * 3.5;
      canvas.drawLine(
        Offset(gripRect.left + 2, y),
        Offset(gripRect.right - 2, y),
        gripLinePaint,
      );
    }
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Conical tip (at TOP)
    final tipPath = Path();
    tipPath.moveTo(w * 0.38, h * 0.24);
    tipPath.quadraticBezierTo(w * 0.5, h * 0.06, w * 0.62, h * 0.24);
    tipPath.close();

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E8E8),
        Color(0xFFD0D0D0),
        Color(0xFFB0B0B0),
        Color(0xFFC8C8C8),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Colored tip point (bigger)
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.09),
      w * 0.04,
      Paint()..color = penColor,
    );
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Colored cap at bottom
    final capRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.24,
      height: h * 0.12,
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
      RRect.fromRectAndRadius(capRect, const Radius.circular(4)),
      Paint()..shader = capGradient,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = createHighlightPaint(opacity: 0.55, width: 2.2);

    // Body highlight
    canvas.drawLine(
      Offset(w * 0.38, h * 0.26),
      Offset(w * 0.38, h * 0.76),
      highlightPaint,
    );

    // Grip highlight
    canvas.drawLine(
      Offset(w * 0.38, h * 0.26),
      Offset(w * 0.38, h * 0.38),
      createHighlightPaint(opacity: 0.45, width: 1.5),
    );
  }
}
