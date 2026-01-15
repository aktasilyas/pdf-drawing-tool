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
        center: Offset(w * 0.5, h * 0.5),
        width: w * 0.16,
        height: h * 0.6,
      ),
      const Radius.circular(4),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final shadowPath = buildBodyPath(rect);

    canvas.save();
    canvas.translate(2.5, 3.0);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.16,
      height: h * 0.6,
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
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..shader = outerGradient,
    );

    // Body outline for definition
    final outlinePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      outlinePaint,
    );

    // Inner ink reservoir (colored, visible through transparent body)
    final inkRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.48),
      width: w * 0.07,
      height: h * 0.45,
    );

    final inkGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.4),
        penColor.withOpacity(0.6),
        penColor.withOpacity(0.55),
      ],
    ).createShader(inkRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(inkRect, const Radius.circular(2)),
      Paint()..shader = inkGradient,
    );

    // Rubber grip section (at lower part of body)
    final gripRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.30),
      width: w * 0.17,
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
      RRect.fromRectAndRadius(gripRect, const Radius.circular(2)),
      Paint()..shader = gripGradient,
    );

    // Grip texture lines
    final gripLinePaint = Paint()
      ..color = const Color(0xFF909090).withOpacity(0.5)
      ..strokeWidth = 0.5;

    for (var i = 0; i < 5; i++) {
      final y = gripRect.top + 3 + i * 3.0;
      canvas.drawLine(
        Offset(gripRect.left + 1, y),
        Offset(gripRect.right - 1, y),
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
    tipPath.moveTo(w * 0.43, h * 0.20);
    tipPath.quadraticBezierTo(w * 0.5, h * 0.06, w * 0.57, h * 0.20);
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

    // Colored tip point
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.08),
      w * 0.028,
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
      width: w * 0.14,
      height: h * 0.10,
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
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = createHighlightPaint(opacity: 0.5, width: 1.5);

    // Body highlight
    canvas.drawLine(
      Offset(w * 0.43, h * 0.22),
      Offset(w * 0.43, h * 0.75),
      highlightPaint,
    );

    // Grip highlight
    canvas.drawLine(
      Offset(w * 0.43, h * 0.24),
      Offset(w * 0.43, h * 0.36),
      createHighlightPaint(opacity: 0.4, width: 1.0),
    );
  }
}
