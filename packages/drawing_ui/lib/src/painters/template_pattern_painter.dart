import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// Template pattern'larını çizen base painter.
/// Tema renklerini dışarıdan alır, hardcoded renk kullanmaz.
class TemplatePatternPainter extends CustomPainter {
  final TemplatePattern pattern;
  final double spacingMm;
  final double lineWidth;
  final Color lineColor;
  final Color backgroundColor;
  final Size pageSize;
  final Map<String, dynamic>? extraData;

  // mm → px dönüşüm (72 DPI)
  double get _spacingPx => spacingMm * 72 / 25.4;

  const TemplatePatternPainter({
    required this.pattern,
    required this.spacingMm,
    required this.lineWidth,
    required this.lineColor,
    required this.backgroundColor,
    required this.pageSize,
    this.extraData,
  });

  /// Template'den painter oluştur (tema renkleri ile)
  factory TemplatePatternPainter.fromTemplate(
    Template template, {
    required Color lineColor,
    required Color backgroundColor,
    required Size pageSize,
  }) {
    return TemplatePatternPainter(
      pattern: template.pattern,
      spacingMm: template.spacingMm,
      lineWidth: template.lineWidth,
      lineColor: lineColor,
      backgroundColor: backgroundColor,
      pageSize: pageSize,
      extraData: template.extraData,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    // Pattern çiz
    switch (pattern) {
      case TemplatePattern.blank:
        break;
      case TemplatePattern.thinLines:
      case TemplatePattern.mediumLines:
      case TemplatePattern.thickLines:
        _drawLines(canvas, size);
        break;
      case TemplatePattern.smallGrid:
      case TemplatePattern.mediumGrid:
      case TemplatePattern.largeGrid:
        _drawGrid(canvas, size);
        break;
      case TemplatePattern.smallDots:
      case TemplatePattern.mediumDots:
      case TemplatePattern.largeDots:
        _drawDots(canvas, size);
        break;
      case TemplatePattern.isometric:
        _drawIsometric(canvas, size);
        break;
      case TemplatePattern.hexagonal:
        _drawHexagonal(canvas, size);
        break;
      case TemplatePattern.cornell:
        _drawCornell(canvas, size);
        break;
      case TemplatePattern.music:
        _drawMusic(canvas, size);
        break;
      case TemplatePattern.handwriting:
        _drawHandwriting(canvas, size);
        break;
      case TemplatePattern.calligraphy:
        _drawCalligraphy(canvas, size);
        break;
    }
  }

  Paint get _linePaint => Paint()
    ..color = lineColor
    ..strokeWidth = lineWidth
    ..isAntiAlias = true;

  void _drawLines(Canvas canvas, Size size) {
    final paint = _linePaint;
    final topMargin = _spacingPx * 2;
    for (double y = topMargin; y < size.height; y += _spacingPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = _linePaint;
    for (double x = _spacingPx; x < size.width; x += _spacingPx) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = _spacingPx; y < size.height; y += _spacingPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDots(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final radius = lineWidth * 1.5;
    for (double x = _spacingPx; x < size.width; x += _spacingPx) {
      for (double y = _spacingPx; y < size.height; y += _spacingPx) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  void _drawIsometric(Canvas canvas, Size size) {
    // TODO: Step 2'de implement edilecek
  }

  void _drawHexagonal(Canvas canvas, Size size) {
    // TODO: Step 2'de implement edilecek
  }

  void _drawCornell(Canvas canvas, Size size) {
    // TODO: Step 2'de implement edilecek
  }

  void _drawMusic(Canvas canvas, Size size) {
    // TODO: Step 2'de implement edilecek
  }

  void _drawHandwriting(Canvas canvas, Size size) {
    // TODO: Step 2'de implement edilecek
  }

  void _drawCalligraphy(Canvas canvas, Size size) {
    // TODO: Step 2'de implement edilecek
  }

  @override
  bool shouldRepaint(covariant TemplatePatternPainter oldDelegate) {
    return pattern != oldDelegate.pattern ||
        spacingMm != oldDelegate.spacingMm ||
        lineWidth != oldDelegate.lineWidth ||
        lineColor != oldDelegate.lineColor ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
