import 'dart:math';
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
    final paint = _linePaint;
    final spacing = _spacingPx;
    
    // 30° açılı çizgiler (tan(30°) ≈ 0.577)
    final angle = 0.577;
    
    // Sol üstten sağ alta
    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * angle, size.height),
        paint,
      );
    }
    
    // Sağ üstten sol alta
    for (double x = 0; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * angle, size.height),
        paint,
      );
    }
    
    // Yatay çizgiler
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawHexagonal(Canvas canvas, Size size) {
    final paint = _linePaint;
    final radius = _spacingPx / 2;
    final hexHeight = radius * 1.732; // sqrt(3)
    final hexWidth = radius * 2;
    
    for (double y = radius; y < size.height + radius; y += hexHeight * 0.75) {
      final rowOffset = ((y ~/ (hexHeight * 0.75)) % 2 == 0) ? 0.0 : radius * 1.5;
      for (double x = rowOffset; x < size.width + hexWidth; x += hexWidth * 1.5) {
        _drawHexagon(canvas, Offset(x, y), radius, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * pi / 180;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  void _drawCornell(Canvas canvas, Size size) {
    final paint = _linePaint;
    final marginLeft = extraData?['marginLeft'] as double? ?? size.width * 0.3;
    final marginBottom = extraData?['marginBottom'] as double? ?? size.height * 0.2;
    
    // Sol dikey çizgi (cue column)
    canvas.drawLine(
      Offset(marginLeft, 0),
      Offset(marginLeft, size.height - marginBottom),
      paint..strokeWidth = lineWidth * 2,
    );
    
    // Alt yatay çizgi (summary)
    canvas.drawLine(
      Offset(0, size.height - marginBottom),
      Offset(size.width, size.height - marginBottom),
      paint..strokeWidth = lineWidth * 2,
    );
    
    // Not alma alanında yatay çizgiler
    paint.strokeWidth = lineWidth;
    for (double y = _spacingPx * 2; y < size.height - marginBottom; y += _spacingPx) {
      canvas.drawLine(Offset(marginLeft + 10, y), Offset(size.width, y), paint);
    }
  }

  void _drawMusic(Canvas canvas, Size size) {
    final paint = _linePaint;
    
    // Staff içi çizgi aralığı (her staff 5 çizgiden oluşur)
    final staffLineSpacing = _spacingPx * 0.25; // 2mm arası (8mm / 4 = 2mm)
    final staffHeight = staffLineSpacing * 4; // 5 çizgi = 4 aralık
    final staffGroupSpacing = _spacingPx * 2; // Staff grupları arası 16mm
    
    double y = _spacingPx; // Üstten başlangıç
    
    while (y + staffHeight < size.height) {
      // 5 çizgili staff çiz
      for (int i = 0; i < 5; i++) {
        final lineY = y + (i * staffLineSpacing);
        canvas.drawLine(
          Offset(0, lineY),
          Offset(size.width, lineY),
          paint,
        );
      }
      // Bir sonraki staff grubuna geç
      y += staffHeight + staffGroupSpacing;
    }
  }

  void _drawHandwriting(Canvas canvas, Size size) {
    final paint = _linePaint;
    final topMargin = _spacingPx * 2;
    
    for (double y = topMargin; y < size.height; y += _spacingPx) {
      // Ana baseline
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      
      // Orta çizgi (dashed effect için daha açık renk)
      final midY = y - _spacingPx * 0.4;
      if (midY > topMargin) {
        canvas.drawLine(
          Offset(0, midY),
          Offset(size.width, midY),
          paint..color = lineColor.withValues(alpha: 0.4),
        );
        paint.color = lineColor; // Reset
      }
    }
  }

  void _drawCalligraphy(Canvas canvas, Size size) {
    final paint = _linePaint;
    final angle = 0.364; // tan(20°) - kaligrafi açısı
    
    // Yatay baseline'lar
    for (double y = _spacingPx * 2; y < size.height; y += _spacingPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Açılı rehber çizgiler
    paint.color = lineColor.withValues(alpha: 0.3);
    for (double x = 0; x < size.width + size.height; x += _spacingPx * 2) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * angle, size.height),
        paint,
      );
    }
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
