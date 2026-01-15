import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium pencil icon painter.
///
/// Classic yellow wood pencil with pink eraser, gold ferrule, and graphite tip.
/// Drawn with TIP POINTING UP (top = writing tip, bottom = eraser).
class PencilIconPainter extends PenIconPainter {
  const PencilIconPainter({
    super.penColor = const Color(0xFF2D2D2D),
    super.isSelected = false,
    super.size = 56.0,
    super.orientation = PenOrientation.vertical,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;

    // Pencil body - vertical, tip UP (thicker)
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.30,
        height: h * 0.52,
      ),
      const Radius.circular(2),
    ));

    // Tip triangle
    path.moveTo(w * 0.35, h * 0.26);
    path.lineTo(w * 0.5, h * 0.08);
    path.lineTo(w * 0.65, h * 0.26);
    path.close();

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

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.30,
      height: h * 0.52,
    );

    // 4-color gradient for cylindrical wood body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFF3E0), // highlight edge (cream)
        Color(0xFFFFE0B2), // light wood
        Color(0xFFFFCC80), // core yellow
        Color(0xFFE6A84C), // shadow + warm reflected
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
      Paint()..shader = bodyGradient,
    );

    // Subtle wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0xFFDDBB88).withOpacity(0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var i = -2; i <= 2; i++) {
      final x = w * 0.5 + i * (w * 0.055);
      canvas.drawLine(
        Offset(x, h * 0.30),
        Offset(x, h * 0.74),
        grainPaint,
      );
    }
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Sharpened wood cone (at TOP)
    final conePath = Path();
    conePath.moveTo(w * 0.35, h * 0.26);
    conePath.lineTo(w * 0.5, h * 0.08);
    conePath.lineTo(w * 0.65, h * 0.26);
    conePath.close();

    final coneGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8D4B8), // light wood
        Color(0xFFD4A574), // mid
        Color(0xFFB8865C), // shadow
      ],
    ).createShader(conePath.getBounds());

    canvas.drawPath(conePath, Paint()..shader = coneGradient);

    // Graphite core - dark with slight sheen (bigger)
    final graphitePath = Path();
    graphitePath.moveTo(w * 0.44, h * 0.16);
    graphitePath.lineTo(w * 0.5, h * 0.08);
    graphitePath.lineTo(w * 0.56, h * 0.16);
    graphitePath.close();

    final graphiteGradient = LinearGradient(
      colors: [
        penColor.withOpacity(0.8),
        penColor,
        penColor.withOpacity(0.9),
      ],
    ).createShader(graphitePath.getBounds());

    canvas.drawPath(graphitePath, Paint()..shader = graphiteGradient);
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Metal ferrule with reflected light (at BOTTOM, above eraser)
    final ferruleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.82),
      width: w * 0.32,
      height: h * 0.07,
    );

    final ferruleGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFD8D8D8), // highlight
        Color(0xFFB0B0B0), // light metal
        Color(0xFF787878), // shadow
        Color(0xFF989898), // reflected light!
      ],
      stops: const [0.0, 0.3, 0.75, 1.0],
    ).createShader(ferruleRect);

    canvas.drawRect(ferruleRect, Paint()..shader = ferruleGradient);

    // Ferrule ridge lines
    final ridgePaint = Paint()
      ..color = const Color(0xFF606060)
      ..strokeWidth = 0.6;

    for (var i = 0; i < 3; i++) {
      final y = ferruleRect.top + 2 + i * 3;
      canvas.drawLine(
        Offset(ferruleRect.left + 1, y),
        Offset(ferruleRect.right - 1, y),
        ridgePaint,
      );
    }

    // Pink eraser with gradient (at BOTTOM)
    final eraserRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.91),
      width: w * 0.28,
      height: h * 0.10,
    );

    final eraserGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFCDD2), // light pink
        Color(0xFFEF9A9A), // pink
        Color(0xFFE57373), // dark pink
        Color(0xFFEF9A9A), // reflected
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(eraserRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(eraserRect, const Radius.circular(2)),
      Paint()..shader = eraserGradient,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Strong white highlight on body left edge
    final highlightPaint = createHighlightPaint(opacity: 0.6, width: 2.5);

    canvas.drawLine(
      Offset(w * 0.37, h * 0.30),
      Offset(w * 0.37, h * 0.76),
      highlightPaint,
    );

    // Small highlight on eraser
    canvas.drawLine(
      Offset(w * 0.39, h * 0.87),
      Offset(w * 0.39, h * 0.95),
      createHighlightPaint(opacity: 0.45, width: 1.5),
    );
  }
}
