import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium marker pen icon painter.
///
/// Thick cylindrical body with bullet tip,
/// resembles classic felt-tip markers.
/// Drawn with TIP POINTING UP (top = bullet tip, bottom = cap).
class MarkerIconPainter extends PenIconPainter {
  const MarkerIconPainter({
    super.penColor = const Color(0xFF795548), // Brown default
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
        width: w * 0.22,
        height: h * 0.55,
      ),
      const Radius.circular(3),
    ));

    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final shadowPath = buildBodyPath(rect);

    canvas.save();
    canvas.translate(2.5, 3.5);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.22,
      height: h * 0.55,
    );

    // Thick cylindrical body - ink color with 4-color gradient
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _adjustBrightness(penColor, 0.2), // highlight
        _adjustBrightness(penColor, 0.1), // light mid
        penColor, // core
        _adjustBrightness(penColor, -0.1), // shadow + reflected
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()..shader = bodyGradient,
    );

    // Cap separation line
    final capLine = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.76),
      width: w * 0.22,
      height: h * 0.015,
    );
    canvas.drawRect(
      capLine,
      Paint()..color = penColor.withOpacity(0.5),
    );
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Bullet tip (rounded tip, at TOP)
    final tipPath = Path();
    tipPath.moveTo(w * 0.39, h * 0.22);
    tipPath.quadraticBezierTo(
      w * 0.5,
      h * 0.06,
      w * 0.61,
      h * 0.22,
    );
    tipPath.close();

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _adjustBrightness(penColor, 0.15),
        penColor,
        _adjustBrightness(penColor, -0.1),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Bottom cap
    final capRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.20,
      height: h * 0.10,
    );

    final capGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _adjustBrightness(penColor, 0.15),
        _adjustBrightness(penColor, 0.05),
        penColor,
        _adjustBrightness(penColor, -0.05),
      ],
    ).createShader(capRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(2)),
      Paint()..shader = capGradient,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = createHighlightPaint(opacity: 0.35, width: 2.0);

    // Side highlight on body
    canvas.drawLine(
      Offset(w * 0.41, h * 0.26),
      Offset(w * 0.41, h * 0.72),
      highlightPaint,
    );

    // Tip highlight
    canvas.drawLine(
      Offset(w * 0.43, h * 0.14),
      Offset(w * 0.43, h * 0.20),
      createHighlightPaint(opacity: 0.3, width: 1.2),
    );
  }

  /// Adjust color brightness.
  Color _adjustBrightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
