import 'package:flutter/material.dart';

/// Simple template pattern painter for document list thumbnails
class DocumentThumbnailPainter extends CustomPainter {
  final String templateId;

  const DocumentThumbnailPainter(this.templateId);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Template'e göre pattern çiz
    switch (templateId) {
      case 'lined':
      case 'thin_lined':
        _drawLines(canvas, size, paint);
        break;
      case 'grid':
      case 'small_grid':
        _drawGrid(canvas, size, paint);
        break;
      case 'dotted':
        _drawDots(canvas, size, paint);
        break;
      case 'cornell':
        _drawCornell(canvas, size, paint);
        break;
      default:
        // Blank template - boş
        break;
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint) {
    final spacing = templateId == 'thin_lined' ? 6.0 : 8.0;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    final spacing = templateId == 'small_grid' ? 5.0 : 10.0;
    
    // Horizontal lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Vertical lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    final dotPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;
    
    const spacing = 10.0;
    for (double y = spacing; y < size.height; y += spacing) {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }
  }

  void _drawCornell(Canvas canvas, Size size, Paint paint) {
    // Left margin
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      paint,
    );
    
    // Bottom summary area
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      paint,
    );
    
    // Horizontal lines
    for (double y = 8.0; y < size.height * 0.8; y += 8.0) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
