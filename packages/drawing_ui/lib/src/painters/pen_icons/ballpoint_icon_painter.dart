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

    // Body
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.45),
        width: w * 0.14,
        height: h * 0.6,
      ),
      const Radius.circular(3),
    ));

    // Tip
    path.addPath(_createTipPath(w, h), Offset.zero);

    return path;
  }

  Path _createTipPath(double w, double h) {
    final path = Path();
    path.moveTo(w * 0.43, h * 0.15);
    path.quadraticBezierTo(w * 0.5, h * 0.02, w * 0.57, h * 0.15);
    path.close();
    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
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
      center: Offset(w * 0.5, h * 0.45),
      width: w * 0.14,
      height: h * 0.6,
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
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()..shader = bodyGradient,
    );

    // Grip section (rubber texture, below body center)
    final gripRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.32),
      width: w * 0.15,
      height: h * 0.12,
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
      RRect.fromRectAndRadius(gripRect, const Radius.circular(2)),
      Paint()..shader = gripGradient,
    );

    // Grip texture lines
    final gripLinePaint = Paint()
      ..color = const Color(0xFF808080).withOpacity(0.4)
      ..strokeWidth = 0.5;

    for (var i = 0; i < 5; i++) {
      final y = gripRect.top + 2 + i * 2.5;
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

    // Ball point
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.04),
      w * 0.028,
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
      width: w * 0.10,
      height: h * 0.08,
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
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(1.5)),
      Paint()..shader = buttonGradient,
    );

    // Metal clip (on right side, from bottom going up)
    final clipPath = Path();
    clipPath.moveTo(w * 0.58, h * 0.82);
    clipPath.lineTo(w * 0.62, h * 0.82);
    clipPath.lineTo(w * 0.62, h * 0.45);
    clipPath.quadraticBezierTo(w * 0.62, h * 0.40, w * 0.58, h * 0.40);
    clipPath.lineTo(w * 0.58, h * 0.42);
    clipPath.lineTo(w * 0.60, h * 0.42);
    clipPath.lineTo(w * 0.60, h * 0.80);
    clipPath.lineTo(w * 0.58, h * 0.80);
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

    final highlightPaint = createHighlightPaint(opacity: 0.6, width: 1.5);

    // Body highlight
    canvas.drawLine(
      Offset(w * 0.44, h * 0.20),
      Offset(w * 0.44, h * 0.70),
      highlightPaint,
    );

    // Clip highlight
    canvas.drawLine(
      Offset(w * 0.59, h * 0.45),
      Offset(w * 0.59, h * 0.78),
      createHighlightPaint(opacity: 0.4, width: 0.8),
    );
  }
}
