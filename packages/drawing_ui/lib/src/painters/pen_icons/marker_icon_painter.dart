import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Marker pen icon painter.
///
/// Thick cylindrical body with bullet tip,
/// resembles classic felt-tip markers.
class MarkerIconPainter extends PenIconPainter {
  const MarkerIconPainter({
    super.penColor = const Color(0xFF795548), // Brown default
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final centerX = rect.width / 2;
    final centerY = rect.height / 2;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 12, height: 36),
      const Radius.circular(3),
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

    // Thick cylindrical body - ink color
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 2),
      width: 12,
      height: 34,
    );

    final bodyPaint = gradientPaint(
      bodyRect,
      penColor.withAlpha(230), // 0.9 opacity
      penColor,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      bodyPaint,
    );

    // Cap line
    final capLine = Rect.fromCenter(
      center: Offset(centerX, centerY - 16),
      width: 12,
      height: 2,
    );
    canvas.drawRect(capLine, Paint()..color = penColor.withAlpha(128)); // 0.5

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

    // Bullet tip (rounded tip)
    final tipPath = Path();
    tipPath.moveTo(centerX - 6, centerY + 15);
    tipPath.quadraticBezierTo(
      centerX,
      centerY + 26,
      centerX + 6,
      centerY + 15,
    );
    tipPath.close();

    canvas.drawPath(tipPath, Paint()..color = penColor);

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

    // Top cap
    final capRect = Rect.fromCenter(
      center: Offset(centerX, centerY - 19),
      width: 10,
      height: 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(2)),
      Paint()..color = penColor,
    );

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

    // Side highlight
    canvas.drawLine(
      Offset(centerX - 5, centerY - 14),
      Offset(centerX - 5, centerY + 10),
      highlightPaint(opacity: 0.25),
    );

    canvas.restore();
  }
}
