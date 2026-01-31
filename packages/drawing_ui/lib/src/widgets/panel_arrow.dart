import 'package:flutter/material.dart';
import 'package:drawing_ui/src/utils/anchor_position_calculator.dart';

/// Arrow widget that points to the anchor button
class PanelArrow extends StatelessWidget {
  const PanelArrow({
    super.key,
    required this.direction,
    required this.offset,
    this.size = 12.0,
    this.color = Colors.white,
  });

  final ArrowDirection direction;
  final double offset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: _getCanvasSize(),
      painter: _PanelArrowPainter(
        direction: direction,
        offset: offset,
        arrowSize: size,
        color: color,
      ),
    );
  }

  Size _getCanvasSize() {
    switch (direction) {
      case ArrowDirection.up:
      case ArrowDirection.down:
        return Size(size * 2, size);
      case ArrowDirection.left:
      case ArrowDirection.right:
        return Size(size, size * 2);
    }
  }
}

class _PanelArrowPainter extends CustomPainter {
  const _PanelArrowPainter({
    required this.direction,
    required this.offset,
    required this.arrowSize,
    required this.color,
  });

  final ArrowDirection direction;
  final double offset;
  final double arrowSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 25.0 / 255.0) // 0.1 * 255 ≈ 25
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();

    switch (direction) {
      case ArrowDirection.down:
        // Triangle pointing down (panel is above anchor)
        path.moveTo(size.width / 2, size.height); // Bottom point
        path.lineTo(0, 0); // Top left
        path.lineTo(size.width, 0); // Top right
        break;

      case ArrowDirection.up:
        // Triangle pointing up (panel is below anchor)
        path.moveTo(size.width / 2, 0); // Top point
        path.lineTo(0, size.height); // Bottom left
        path.lineTo(size.width, size.height); // Bottom right
        break;

      case ArrowDirection.right:
        // Triangle pointing right (panel is to the left of anchor)
        path.moveTo(size.width, size.height / 2); // Right point
        path.lineTo(0, 0); // Top left
        path.lineTo(0, size.height); // Bottom left
        break;

      case ArrowDirection.left:
        // Triangle pointing left (panel is to the right of anchor)
        path.moveTo(0, size.height / 2); // Left point
        path.lineTo(size.width, 0); // Top right
        path.lineTo(size.width, size.height); // Bottom right
        break;
    }

    path.close();

    // Draw shadow
    canvas.drawPath(path, shadowPaint);
    
    // Draw arrow
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PanelArrowPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.offset != offset ||
        oldDelegate.arrowSize != arrowSize ||
        oldDelegate.color != color;
  }
}
