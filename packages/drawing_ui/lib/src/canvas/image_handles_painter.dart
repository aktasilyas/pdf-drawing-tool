import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_handles_geometry.dart';

/// Paints selection border, 4 corner handles, and rotation handle with arrow icon.
class ImageHandlesPainter extends CustomPainter {
  final ImageElement image;
  final Color selectionColor;
  static const double _r = 8.0;

  final Paint _stroke;
  final Paint _fill = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  final Paint _arrowStroke;
  final Paint _arrowFill;
  final Path _arrowHead = Path();

  ImageHandlesPainter({required this.image, required this.selectionColor})
      : _stroke = Paint()
          ..color = selectionColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
        _arrowStroke = Paint()
          ..color = selectionColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
        _arrowFill = Paint()
          ..color = selectionColor
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(image.x, image.y, image.width, image.height);
    final c = ImageHandlesGeometry.center(image);

    canvas.save();
    if (image.rotation != 0) {
      canvas.translate(c.dx, c.dy);
      canvas.rotate(image.rotation);
      canvas.translate(-c.dx, -c.dy);
    }

    canvas.drawRect(rect, _stroke);

    _drawHandle(canvas, rect.topLeft);
    _drawHandle(canvas, rect.topRight);
    _drawHandle(canvas, rect.bottomLeft);
    _drawHandle(canvas, rect.bottomRight);

    final topCenter = Offset(c.dx, image.y);
    final rotHandle = ImageHandlesGeometry.rotHandleLocal(image);
    canvas.drawLine(topCenter, rotHandle, _stroke);
    _drawHandle(canvas, rotHandle);
    _drawRotationArrow(canvas, rotHandle);

    canvas.restore();
  }

  void _drawHandle(Canvas canvas, Offset center) {
    canvas.drawCircle(center, _r, _fill);
    canvas.drawCircle(center, _r, _stroke);
  }

  /// Draws a small circular arrow (↻) inside the rotation handle circle.
  void _drawRotationArrow(Canvas canvas, Offset center) {
    const arcRadius = 4.0;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
    canvas.drawArc(
        arcRect, -math.pi * 0.75, math.pi * 1.5, false, _arrowStroke);

    final tip = Offset(
      center.dx + arcRadius * math.cos(math.pi * 0.75),
      center.dy + arcRadius * math.sin(math.pi * 0.75),
    );
    _arrowHead
      ..reset()
      ..moveTo(tip.dx - 3, tip.dy - 1)
      ..lineTo(tip.dx + 1, tip.dy - 3)
      ..lineTo(tip.dx + 1, tip.dy + 2)
      ..close();
    canvas.drawPath(_arrowHead, _arrowFill);
  }

  @override
  bool shouldRepaint(ImageHandlesPainter oldDelegate) =>
      ImageHandlesGeometry.changed(oldDelegate.image, image) ||
      oldDelegate.selectionColor != selectionColor;
}
