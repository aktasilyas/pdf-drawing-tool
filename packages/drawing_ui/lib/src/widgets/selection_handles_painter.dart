import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Paints selection handles: blue border, 4 corner circles, 4 edge rectangles,
/// and rotation handle with refresh icon. Supports live move/rotation/scale preview.
class SelectionHandlesPainter extends CustomPainter {
  final BoundingBox bounds;
  final Offset moveDelta;
  final double rotation;
  final double scaleX;
  final double scaleY;

  /// Corner handle radius (bigger for easier touch-to-scale).
  static const double handleRadius = 10.0;

  /// Edge handle dimensions.
  static const double edgeHandleWidth = 12.0;
  static const double edgeHandleHeight = 5.0;

  /// Rotation handle radius (larger, with icon inside).
  static const double rotHandleRadius = 14.0;

  /// Distance from top-center to rotation handle.
  static const double rotHandleDist = 36.0;

  SelectionHandlesPainter({
    required this.bounds,
    required this.moveDelta,
    required this.rotation,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = (bounds.left + bounds.right) / 2;
    final cy = (bounds.top + bounds.bottom) / 2;

    // Compute scaled bounds
    final halfW = (bounds.right - bounds.left) / 2 * scaleX;
    final halfH = (bounds.bottom - bounds.top) / 2 * scaleY;
    final rect = Rect.fromLTRB(
      cx - halfW, cy - halfH, cx + halfW, cy + halfH,
    );

    canvas.save();
    canvas.translate(cx + moveDelta.dx, cy + moveDelta.dy);
    if (rotation != 0) canvas.rotate(rotation);
    canvas.translate(-cx, -cy);

    final border = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, border);

    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleStroke = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Corner handles (circles)
    for (final c in [
      rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight,
    ]) {
      canvas.drawCircle(c, handleRadius, fill);
      canvas.drawCircle(c, handleRadius, handleStroke);
    }

    // Edge handles (rounded rectangles)
    _drawEdgeHandle(canvas, fill, handleStroke,
        Offset(rect.center.dx, rect.top), true);
    _drawEdgeHandle(canvas, fill, handleStroke,
        Offset(rect.center.dx, rect.bottom), true);
    _drawEdgeHandle(canvas, fill, handleStroke,
        Offset(rect.left, rect.center.dy), false);
    _drawEdgeHandle(canvas, fill, handleStroke,
        Offset(rect.right, rect.center.dy), false);

    // Rotation handle: line + large circle with refresh icon
    final topCenter = Offset(rect.center.dx, rect.top);
    final rotHandle = Offset(rect.center.dx, rect.top - rotHandleDist);
    canvas.drawLine(topCenter, rotHandle, border);
    canvas.drawCircle(rotHandle, rotHandleRadius, fill);
    canvas.drawCircle(rotHandle, rotHandleRadius, handleStroke);
    _drawRotationIcon(canvas, rotHandle);

    canvas.restore();
  }

  void _drawEdgeHandle(
    Canvas canvas, Paint fill, Paint stroke, Offset center, bool horizontal,
  ) {
    final w = horizontal ? edgeHandleWidth : edgeHandleHeight;
    final h = horizontal ? edgeHandleHeight : edgeHandleWidth;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
  }

  void _drawRotationIcon(Canvas canvas, Offset center) {
    final iconData = PhosphorIconsLight.arrowsClockwise;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          fontSize: rotHandleRadius * 1.4,
          color: const Color(0xFF2196F3),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant SelectionHandlesPainter old) {
    return old.bounds != bounds ||
        old.moveDelta != moveDelta ||
        old.rotation != rotation ||
        old.scaleX != scaleX ||
        old.scaleY != scaleY;
  }
}
