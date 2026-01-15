import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium ballpoint pen icon painter.
///
/// Sleek cylindrical white body with click mechanism,
/// metal clip, rubber grip, and fine ballpoint tip.
/// Drawn with TIP POINTING UP (top = ball tip, bottom = click button).
class BallpointIconPainter extends PenIconPainter {
  const BallpointIconPainter({
    super.penColor = const Color(0xFF1565C0),
    super.isSelected = false,
    super.size = 56.0,
    super.orientation = PenOrientation.vertical,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;

    // Body (thicker)
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.48),
        width: w * 0.26,
        height: h * 0.58,
      ),
      const Radius.circular(4),
    ));

    // Tip
    path.addPath(_createTipPath(w, h), Offset.zero);

    return path;
  }

  Path _createTipPath(double w, double h) {
    final path = Path();
    path.moveTo(w * 0.38, h * 0.19);
    path.quadraticBezierTo(w * 0.5, h * 0.04, w * 0.62, h * 0.19);
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
    canvas.translate(3.5, 4);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.48),
      width: w * 0.26,
      height: h * 0.58,
    );

    // 5-color glossy white/cream plastic body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFFFFF), // bright highlight
        Color(0xFFF8F8F8), // white
        Color(0xFFEEEEEE), // light gray
        Color(0xFFE0E0E0), // shadow
        Color(0xFFEAEAEA), // reflected
      ],
      stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..shader = bodyGradient,
    );

    // Grip section (rubber texture, below body center)
    final gripRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.34),
      width: w * 0.27,
      height: h * 0.14,
    );

    final gripGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFD0D0D0),
        Color(0xFFB8B8B8),
        Color(0xFF909090),
        Color(0xFFA8A8A8),
      ],
    ).createShader(gripRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(gripRect, const Radius.circular(3)),
      Paint()..shader = gripGradient,
    );

    // Grip texture lines
    final gripLinePaint = Paint()
      ..color = const Color(0xFF808080).withOpacity(0.45)
      ..strokeWidth = 0.7;

    for (var i = 0; i < 4; i++) {
      final y = gripRect.top + 3 + i * 3.5;
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

    // Metal cone tip (at TOP)
    final tipPath = _createTipPath(w, h);

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFD0D0D0),
        Color(0xFFA8A8A8),
        Color(0xFF707070),
        Color(0xFF909090),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Ball point (bigger)
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.06),
      w * 0.04,
      Paint()..color = penColor,
    );
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Click button on top (at BOTTOM of icon)
    final buttonRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.16,
      height: h * 0.10,
    );

    final buttonGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        penColor.withOpacity(0.9),
        penColor,
        penColor.withOpacity(0.7),
      ],
    ).createShader(buttonRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(2)),
      Paint()..shader = buttonGradient,
    );

    // Metal clip (on right side, from bottom going up)
    final clipPath = Path();
    clipPath.moveTo(w * 0.64, h * 0.82);
    clipPath.lineTo(w * 0.70, h * 0.82);
    clipPath.lineTo(w * 0.70, h * 0.45);
    clipPath.quadraticBezierTo(w * 0.70, h * 0.40, w * 0.64, h * 0.40);
    clipPath.lineTo(w * 0.64, h * 0.42);
    clipPath.lineTo(w * 0.68, h * 0.42);
    clipPath.lineTo(w * 0.68, h * 0.80);
    clipPath.lineTo(w * 0.64, h * 0.80);
    clipPath.close();

    final clipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E8E8),
        Color(0xFFC0C0C0),
        Color(0xFF909090),
        Color(0xFFB0B0B0),
      ],
    ).createShader(clipPath.getBounds());

    canvas.drawPath(clipPath, Paint()..shader = clipGradient);
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = createHighlightPaint(opacity: 0.65, width: 2.2);

    // Body highlight
    canvas.drawLine(
      Offset(w * 0.38, h * 0.22),
      Offset(w * 0.38, h * 0.72),
      highlightPaint,
    );

    // Clip highlight
    canvas.drawLine(
      Offset(w * 0.65, h * 0.45),
      Offset(w * 0.65, h * 0.78),
      createHighlightPaint(opacity: 0.45, width: 1.0),
    );
  }
}
