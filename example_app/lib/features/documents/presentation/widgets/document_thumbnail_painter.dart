/// StarNote Document Thumbnail Painter
///
/// Doküman thumbnail'ı için template pattern çizen CustomPainter.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Template pattern çizen painter
class DocumentThumbnailPainter extends CustomPainter {
  final String templateId;

  DocumentThumbnailPainter(this.templateId);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineLight
      ..strokeWidth = 0.5;

    switch (templateId) {
      case 'small_grid':
        _drawGrid(canvas, size, paint, 10);
        break;
      case 'large_grid':
        _drawGrid(canvas, size, paint, 20);
        break;
      case 'thin_lined':
        _drawLines(canvas, size, paint, 15);
        break;
      case 'thick_lined':
        _drawLines(canvas, size, paint, 25);
        break;
      case 'dotted':
        _drawDots(canvas, size, paint);
        break;
      default:
        // Blank - no pattern
        break;
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint, double spacing) {
    // Vertical lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint, double spacing) {
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    const spacing = 15.0;
    paint.style = PaintingStyle.fill;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
