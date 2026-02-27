import 'dart:math';
import 'package:flutter/material.dart';

/// Mixin providing planner & utility structural template painters.
///
/// Contains: dailyPlanner, weeklyPlanner, monthlyPlanner,
/// todoList, checklist, meetingNotes + shared helpers.
/// All measurements proportional (no fixed pixels).
/// All colors derive from lineColor (no hardcoded colors).
mixin TemplatePlannerPainters {
  Color get lineColor;
  double get lineWidth;
  Map<String, dynamic>? get extraData;
  double get spacingPx;
  Paint get linePaint;

  // === HELPERS ===

  /// Yatay ayırıcı çizgi (kalın)
  void drawDividerLine(
    Canvas canvas, double y, double startX, double endX, Paint paint,
  ) {
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      paint..strokeWidth = lineWidth * 2,
    );
  }

  /// Checkbox (boş kare, rounded)
  void drawCheckboxRect(
    Canvas canvas, Offset topLeft, double size, Paint paint,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size),
      Radius.circular(size * 0.15),
    );
    canvas.drawRRect(
      rect,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth,
    );
  }

  // === DRAW METHODS ===

  void drawDailyPlanner(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.08;
    final dividerX = size.width * 0.62;

    // Header ayırıcı
    drawDividerLine(canvas, headerH, margin, size.width - margin, paint);

    // Dikey bölme çizgisi
    canvas.drawLine(
      Offset(dividerX, headerH),
      Offset(dividerX, size.height - margin),
      paint..strokeWidth = lineWidth * 1.5,
    );

    // Sol: Saatlik çizgiler
    final startHour = (extraData?['startHour'] as int?) ?? 6;
    final endHour = (extraData?['endHour'] as int?) ?? 22;
    final totalHours = endHour - startHour;
    final availableH = size.height - headerH - margin;
    final hourH = availableH / totalHours;

    paint.strokeWidth = lineWidth;
    for (var i = 0; i <= totalHours; i++) {
      final y = headerH + (i * hourH);
      canvas.drawLine(
        Offset(margin, y),
        Offset(dividerX - margin, y),
        paint,
      );
      // Yarım saat çizgisi (kısa, soluk)
      if (i < totalHours) {
        final halfY = y + hourH * 0.5;
        canvas.drawLine(
          Offset(margin + dividerX * 0.15, halfY),
          Offset(dividerX - margin, halfY),
          Paint()
            ..color = lineColor.withValues(alpha: 0.3)
            ..strokeWidth = lineWidth * 0.5,
        );
      }
    }

    // Sağ üst: Hedef checkbox'ları
    _drawDailyPlannerRightPanel(canvas, size, headerH, dividerX, margin,
        availableH, paint);
  }

  void _drawDailyPlannerRightPanel(
    Canvas canvas, Size size, double headerH, double dividerX,
    double margin, double availableH, Paint paint,
  ) {
    final rightStart = dividerX + margin;
    final rightEnd = size.width - margin;
    final goalSectionH = availableH * 0.4;
    final goalDividerY = headerH + goalSectionH;

    drawDividerLine(canvas, goalDividerY, rightStart, rightEnd, paint);

    final checkboxSize = min(size.width, size.height) * 0.025;
    final goalLineH = goalSectionH / 6;
    for (var i = 0; i < 5; i++) {
      final y = headerH + margin + (i * goalLineH);
      drawCheckboxRect(
        canvas,
        Offset(rightStart, y + goalLineH * 0.2),
        checkboxSize,
        Paint()..color = lineColor,
      );
      canvas.drawLine(
        Offset(rightStart + checkboxSize + margin,
            y + goalLineH * 0.5 + checkboxSize * 0.5),
        Offset(rightEnd, y + goalLineH * 0.5 + checkboxSize * 0.5),
        Paint()
          ..color = lineColor.withValues(alpha: 0.4)
          ..strokeWidth = lineWidth * 0.5,
      );
    }

    // Sağ alt: Not çizgileri
    paint
      ..strokeWidth = lineWidth
      ..color = lineColor.withValues(alpha: 0.5);
    for (var y = goalDividerY + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(Offset(rightStart, y), Offset(rightEnd, y), paint);
    }
  }

  void drawWeeklyPlanner(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.03;
    final headerH = size.height * 0.06;
    final footerH = size.height * 0.15;

    // Header + Footer ayırıcılar
    drawDividerLine(canvas, headerH, margin, size.width - margin, paint);
    drawDividerLine(
        canvas, size.height - footerH, margin, size.width - margin, paint);

    // 7 gün sütunları
    const dayCount = 7;
    final dayW = (size.width - margin * 2) / dayCount;
    for (var i = 1; i < dayCount; i++) {
      final x = margin + (i * dayW);
      canvas.drawLine(
        Offset(x, headerH),
        Offset(x, size.height - footerH),
        paint..strokeWidth = lineWidth,
      );
    }

    // Yatay çizgiler (gün alanlarında)
    paint
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = lineWidth * 0.5;
    for (var y = headerH + spacingPx;
        y < size.height - footerH;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), paint);
    }

    // Footer: not çizgileri
    paint.color = lineColor.withValues(alpha: 0.5);
    for (var y = size.height - footerH + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }

  void drawMonthlyPlanner(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.03;
    final headerH = size.height * 0.08;
    final footerH = size.height * 0.12;
    final gridH = size.height - headerH - footerH;
    final cols = (extraData?['gridCols'] as int?) ?? 7;
    final rows = (extraData?['gridRows'] as int?) ?? 6;

    drawDividerLine(canvas, headerH, margin, size.width - margin, paint);
    drawDividerLine(
        canvas, size.height - footerH, margin, size.width - margin, paint);

    final cellW = (size.width - margin * 2) / cols;
    final cellH = gridH / rows;

    // Dikey + yatay grid çizgileri
    for (var i = 0; i <= cols; i++) {
      final x = margin + (i * cellW);
      canvas.drawLine(
        Offset(x, headerH),
        Offset(x, size.height - footerH),
        paint..strokeWidth = lineWidth,
      );
    }
    for (var i = 0; i <= rows; i++) {
      final y = headerH + (i * cellH);
      canvas.drawLine(
        Offset(margin, y),
        Offset(size.width - margin, y),
        paint..strokeWidth = lineWidth,
      );
    }

    // Footer: not çizgileri
    paint
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = lineWidth * 0.5;
    for (var y = size.height - footerH + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }

  void drawTodoList(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.07;
    final priorityW = size.width * 0.06;
    final checkboxW = size.width * 0.06;
    final checkboxSize = min(size.width, size.height) * 0.022;
    final rowH = spacingPx * 1.2;

    drawDividerLine(canvas, headerH, margin, size.width - margin, paint);

    // Dikey ayırıcılar: öncelik | checkbox | içerik
    final colPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = lineWidth * 0.5;
    canvas.drawLine(
      Offset(margin + priorityW, headerH),
      Offset(margin + priorityW, size.height - margin),
      colPaint,
    );
    canvas.drawLine(
      Offset(margin + priorityW + checkboxW, headerH),
      Offset(margin + priorityW + checkboxW, size.height - margin),
      colPaint,
    );

    // Satırlar
    paint
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = lineWidth * 0.5;
    for (var y = headerH + rowH; y < size.height - margin; y += rowH) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), paint);
      // Checkbox
      final cbY = y - rowH * 0.5 - checkboxSize * 0.5;
      final cbX = margin + priorityW + (checkboxW - checkboxSize) * 0.5;
      drawCheckboxRect(
          canvas, Offset(cbX, cbY), checkboxSize, Paint()..color = lineColor);
    }
  }

  void drawChecklist(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.05;
    final headerH = size.height * 0.06;
    final checkboxSize = min(size.width, size.height) * 0.02;
    final checkboxMargin = size.width * 0.08;
    final rowH = spacingPx;

    drawDividerLine(canvas, headerH, margin, size.width - margin, paint);

    paint
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = lineWidth * 0.5;
    for (var y = headerH + rowH; y < size.height - margin; y += rowH) {
      final cbY = y - rowH * 0.5 - checkboxSize * 0.5;
      drawCheckboxRect(
          canvas, Offset(margin, cbY), checkboxSize, Paint()..color = lineColor);
      canvas.drawLine(
          Offset(checkboxMargin, y), Offset(size.width - margin, y), paint);
    }
  }

  void drawMeetingNotes(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.05;
    final headerH = size.height * 0.08;
    final s1H = size.height * 0.15;
    final s2H = size.height * 0.15;
    final s4H = size.height * 0.20;

    final s1Y = headerH;
    final s2Y = s1Y + s1H;
    final s3Y = s2Y + s2H;
    final s4Y = size.height - s4H;

    // Bölüm ayırıcılar
    for (final y in [s1Y, s2Y, s3Y, s4Y]) {
      drawDividerLine(canvas, y, margin, size.width - margin, paint);
    }

    // Bölüm 1-2 + 3: çizgiler
    paint
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = lineWidth * 0.5;
    for (final bounds in [
      [s1Y, s2Y],
      [s2Y, s3Y],
      [s3Y, s4Y],
    ]) {
      for (var y = bounds[0] + spacingPx;
          y < bounds[1] - margin * 0.3;
          y += spacingPx) {
        canvas.drawLine(
            Offset(margin, y), Offset(size.width - margin, y), paint);
      }
    }

    // Bölüm 4: aksiyon checkbox'ları
    final checkboxSize = min(size.width, size.height) * 0.02;
    final actionRowH = spacingPx * 1.2;
    for (var y = s4Y + actionRowH; y < size.height - margin; y += actionRowH) {
      drawCheckboxRect(
        canvas,
        Offset(margin, y - checkboxSize * 0.5 - actionRowH * 0.2),
        checkboxSize,
        Paint()..color = lineColor,
      );
      canvas.drawLine(
        Offset(margin + checkboxSize + margin * 0.5, y),
        Offset(size.width - margin, y),
        paint,
      );
    }
  }
}
