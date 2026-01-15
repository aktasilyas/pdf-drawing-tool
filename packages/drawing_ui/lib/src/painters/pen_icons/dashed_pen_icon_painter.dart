import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Premium dashed pen icon painter.
///
/// Similar to ballpoint pen but with dash pattern indicator
/// on the body to show it draws dashed lines.
/// Drawn with TIP POINTING UP (top = ball tip, bottom = colored band).
class DashedPenIconPainter extends PenIconPainter {
  const DashedPenIconPainter({
    super.penColor = const Color(0xFF1A1A1A),
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
        width: w * 0.14,
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
      width: w * 0.14,
      height: h * 0.6,
    );

    // Light gray glossy body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFFFFF), // bright highlight
        Color(0xFFF8F8F8), // white
        Color(0xFFECECEC), // light gray
        Color(0xFFE0E0E0), // shadow
        Color(0xFFE8E8E8), // reflected
      ],
      stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
    ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..shader = bodyGradient,
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
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    // Metal tip cone (at TOP)
    final tipPath = Path();
    tipPath.moveTo(w * 0.43, h * 0.20);
    tipPath.lineTo(w * 0.5, h * 0.06);
    tipPath.lineTo(w * 0.57, h * 0.20);
    tipPath.close();

    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFD0D0D0),
        Color(0xFFB8B8B8),
        Color(0xFF909090),
        Color(0xFFA8A8A8),
      ],
    ).createShader(tipPath.getBounds());

    canvas.drawPath(tipPath, Paint()..shader = tipGradient);

    // Ball point
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

    // Dash pattern indicator on body (3 short dashes)
    final dashPaint = Paint()
      ..color = penColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w * 0.46, h * 0.42 + i * (h * 0.08)),
        Offset(w * 0.54, h * 0.42 + i * (h * 0.08)),
        dashPaint,
      );
    }

    // Colored band at bottom
    final bandRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.86),
      width: w * 0.14,
      height: h * 0.08,
    );

    final bandGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFF64B5F6), // light blue highlight
        Color(0xFF4A9DFF), // blue
        Color(0xFF2196F3), // darker blue
        Color(0xFF42A5F5), // reflected
      ],
    ).createShader(bandRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, const Radius.circular(2)),
      Paint()..shader = bandGradient,
    );
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;

    final highlightPaint = createHighlightPaint(opacity: 0.6, width: 1.5);

    // Body highlight
    canvas.drawLine(
      Offset(w * 0.44, h * 0.22),
      Offset(w * 0.44, h * 0.78),
      highlightPaint,
    );
  }
}
