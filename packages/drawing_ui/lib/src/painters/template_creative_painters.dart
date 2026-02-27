import 'dart:math';
import 'package:flutter/material.dart';

/// Mixin providing creative & journal structural template painters.
///
/// Contains: bulletJournal, gratitudeJournal, storyboard, wireframe.
/// All measurements proportional. All colors derive from lineColor.
mixin TemplateCreativePainters {
  Color get lineColor;
  double get lineWidth;
  Map<String, dynamic>? get extraData;
  double get spacingPx;
  Paint get linePaint;

  /// Yatay ayırıcı çizgi (kalın) — library-private duplicate
  void _drawCreativeDivider(
    Canvas canvas, double y, double startX, double endX, Paint paint,
  ) {
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      paint..strokeWidth = lineWidth * 2,
    );
  }

  // === DRAW METHODS ===

  void drawBulletJournal(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.06;
    final bulletMargin = size.width * 0.08;

    _drawCreativeDivider(canvas, headerH, margin, size.width - margin, paint);

    // Sol kenar çizgisi (bullet alanı ayırıcı)
    canvas.drawLine(
      Offset(bulletMargin, headerH),
      Offset(bulletMargin, size.height - margin),
      Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..strokeWidth = lineWidth,
    );

    // Yatay çizgiler + bullet noktaları
    paint
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = lineWidth * 0.5;
    for (var y = headerH + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
        Offset(bulletMargin + margin * 0.5, y),
        Offset(size.width - margin, y),
        paint,
      );
      // Bullet noktası
      final bulletY = y - spacingPx * 0.5;
      if (bulletY > headerH) {
        final bulletR = min(size.width, size.height) * 0.005;
        canvas.drawCircle(
          Offset(bulletMargin * 0.55, bulletY),
          bulletR,
          Paint()
            ..color = lineColor.withValues(alpha: 0.6)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Opsiyonel: arka plan dot grid
    if (extraData?['dotGrid'] == true) {
      _drawBulletDotGrid(canvas, size, headerH, bulletMargin, margin);
    }
  }

  void _drawBulletDotGrid(
    Canvas canvas, Size size, double headerH,
    double bulletMargin, double margin,
  ) {
    final dotPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final dotSpacing = spacingPx * 0.5;
    final dotR = lineWidth * 0.5;
    for (var x = bulletMargin + dotSpacing;
        x < size.width - margin;
        x += dotSpacing) {
      for (var y = headerH + dotSpacing;
          y < size.height - margin;
          y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotR, dotPaint);
      }
    }
  }

  void drawGratitudeJournal(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.05;
    final headerH = size.height * 0.08;
    final section1H = size.height * 0.25;
    final section2H = size.height * 0.35;

    final section1Y = headerH;
    final section2Y = section1Y + section1H;
    final section3Y = section2Y + section2H;

    // Bölüm ayırıcılar
    _drawCreativeDivider(canvas, headerH, margin, size.width - margin, paint);
    _drawCreativeDivider(canvas, section2Y, margin, size.width - margin, paint);
    _drawCreativeDivider(canvas, section3Y, margin, size.width - margin, paint);

    // Bölüm 1: Prompt satırları
    final promptCount = (extraData?['promptCount'] as int?) ?? 3;
    final promptLineH = section1H / (promptCount + 1);
    paint
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = lineWidth * 0.5;
    for (var i = 1; i <= promptCount; i++) {
      final y = section1Y + (i * promptLineH);
      final dotR = min(size.width, size.height) * 0.008;
      canvas.drawCircle(
        Offset(margin + dotR, y),
        dotR,
        Paint()
          ..color = lineColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill,
      );
      canvas.drawLine(
        Offset(margin + dotR * 4, y),
        Offset(size.width - margin, y),
        paint,
      );
    }

    // Bölüm 2: Serbest yazı çizgileri
    for (var y = section2Y + spacingPx;
        y < section3Y - margin * 0.5;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), paint);
    }

    // Bölüm 3: Mood scale + not çizgileri
    _drawGratitudeMoodSection(canvas, size, section3Y, margin);
  }

  void _drawGratitudeMoodSection(
    Canvas canvas, Size size, double section3Y, double margin,
  ) {
    // Mood scale (5 daire)
    if (extraData?['showMoodScale'] != false) {
      final moodY = section3Y + (size.height - section3Y) * 0.4;
      const moodCount = 5;
      final moodSpacing = (size.width - margin * 4) / (moodCount - 1);
      final moodR = min(size.width, size.height) * 0.025;
      final moodPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth;
      for (var i = 0; i < moodCount; i++) {
        final x = margin * 2 + (i * moodSpacing);
        canvas.drawCircle(Offset(x, moodY), moodR, moodPaint);
      }
    }

    // Not çizgileri
    final linePaintAlpha = Paint()
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = lineWidth * 0.5;
    for (var y = section3Y + (size.height - section3Y) * 0.55;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), linePaintAlpha);
    }
  }

  void drawStoryboard(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.05;
    final framesPerPage = (extraData?['framesPerPage'] as int?) ?? 6;
    const cols = 2;
    final rows = (framesPerPage / cols).ceil();

    _drawCreativeDivider(canvas, headerH, margin, size.width - margin, paint);

    final cellW = (size.width - margin * 2) / cols;
    final cellH = (size.height - headerH - margin) / rows;
    final framePadding = cellW * 0.08;

    // Aspect ratio
    final aspectStr = (extraData?['aspectRatio'] as String?) ?? '16:9';
    final parts = aspectStr.split(':');
    final aspect =
        (double.tryParse(parts[0]) ?? 16) / (double.tryParse(parts[1]) ?? 9);

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        _drawStoryboardFrame(
            canvas, size, margin, headerH, row, col, cellW, cellH,
            framePadding, aspect, paint);
      }
    }
  }

  void _drawStoryboardFrame(
    Canvas canvas, Size size, double margin, double headerH,
    int row, int col, double cellW, double cellH,
    double framePadding, double aspect, Paint paint,
  ) {
    final cellX = margin + (col * cellW);
    final cellY = headerH + (row * cellH);

    final frameW = cellW - framePadding * 2;
    var frameH = frameW / aspect;
    if (frameH > cellH * 0.6) frameH = cellH * 0.6;

    final frameX = cellX + framePadding;
    final frameY = cellY + framePadding;

    // Frame kutusu
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(frameX, frameY, frameW, frameH),
      Radius.circular(frameW * 0.01),
    );
    canvas.drawRRect(
      frameRect,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth,
    );

    // Açıklama çizgileri
    final descY = frameY + frameH + framePadding * 0.8;
    final descLineSpacing = cellH * 0.08;
    final descPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = lineWidth * 0.5;
    for (var i = 0; i < 2; i++) {
      final y = descY + (i * descLineSpacing);
      if (y < cellY + cellH - framePadding * 0.5) {
        canvas.drawLine(
            Offset(frameX, y), Offset(frameX + frameW, y), descPaint);
      }
    }
  }

  void drawWireframe(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.05;
    final deviceType = (extraData?['deviceType'] as String?) ?? 'mobile';
    final framesPerPage = (extraData?['framesPerPage'] as int?) ?? 3;

    _drawCreativeDivider(canvas, headerH, margin, size.width - margin, paint);

    final deviceAspect = deviceType == 'tablet' ? 4.0 / 3.0 : 9.0 / 19.5;
    final availableH = size.height - headerH - margin * 2;
    final frameH = availableH / framesPerPage - margin;
    final frameW = frameH * deviceAspect;
    final frameX = (size.width - frameW) * 0.5;

    for (var i = 0; i < framesPerPage; i++) {
      final frameY = headerH + margin + (i * (frameH + margin));
      _drawWireframeDevice(
          canvas, frameX, frameY, frameW, frameH, margin, paint);
    }
  }

  void _drawWireframeDevice(
    Canvas canvas, double frameX, double frameY,
    double frameW, double frameH, double margin, Paint paint,
  ) {
    // Device outline
    final deviceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(frameX, frameY, frameW, frameH),
      Radius.circular(frameW * 0.06),
    );
    canvas.drawRRect(
      deviceRect,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth * 1.5,
    );

    // İç grid (opsiyonel)
    if (extraData?['showGrid'] == true) {
      final innerMargin = frameW * 0.05;
      final gridSpacing = frameW * 0.1;
      final gridPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.15)
        ..strokeWidth = lineWidth * 0.3;
      for (var x = frameX + innerMargin + gridSpacing;
          x < frameX + frameW - innerMargin;
          x += gridSpacing) {
        canvas.drawLine(Offset(x, frameY + innerMargin),
            Offset(x, frameY + frameH - innerMargin), gridPaint);
      }
      for (var y = frameY + innerMargin + gridSpacing;
          y < frameY + frameH - innerMargin;
          y += gridSpacing) {
        canvas.drawLine(Offset(frameX + innerMargin, y),
            Offset(frameX + frameW - innerMargin, y), gridPaint);
      }
    }

    // Status bar hint
    final statusY = frameY + frameH * 0.04;
    canvas.drawLine(
      Offset(frameX + frameW * 0.1, statusY),
      Offset(frameX + frameW * 0.9, statusY),
      Paint()
        ..color = lineColor.withValues(alpha: 0.2)
        ..strokeWidth = lineWidth * 0.3,
    );
  }

}
