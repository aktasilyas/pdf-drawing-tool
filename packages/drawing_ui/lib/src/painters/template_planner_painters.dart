import 'dart:math';
import 'dart:ui';

import 'template_structural_helpers.dart';

/// Mixin providing the calendar planner template painters.
///
/// Contains: dailyPlanner, weeklyPlanner, monthlyPlanner.
/// All measurements proportional (no fixed pixels).
/// All colors derive from lineColor (no hardcoded colors).
mixin TemplatePlannerPainters on TemplateStructuralHelpers {
  void drawDailyPlanner(Canvas canvas, Size size) {
    final margin = size.width * 0.04;
    final headerH = size.height * 0.08;
    final dividerX = size.width * 0.62;

    drawDividerLine(canvas, headerH, margin, size.width - margin);

    canvas.drawLine(
      Offset(dividerX, headerH),
      Offset(dividerX, size.height - margin),
      accent.ink15,
    );

    // Left: hourly lines
    final startHour = (extraData?['startHour'] as int?) ?? 6;
    final endHour = (extraData?['endHour'] as int?) ?? 22;
    final totalHours = endHour - startHour;
    final availableH = size.height - headerH - margin;
    final hourH = availableH / totalHours;

    for (var i = 0; i <= totalHours; i++) {
      final y = headerH + (i * hourH);
      canvas.drawLine(
          Offset(margin, y), Offset(dividerX - margin, y), accent.ink);
      // Half-hour line (short, faint)
      if (i < totalHours) {
        final halfY = y + hourH * 0.5;
        canvas.drawLine(
          Offset(margin + dividerX * 0.15, halfY),
          Offset(dividerX - margin, halfY),
          accent.hair3,
        );
      }
    }

    _drawDailyPlannerRightPanel(
        canvas, size, headerH, dividerX, margin, availableH);
  }

  void _drawDailyPlannerRightPanel(
    Canvas canvas,
    Size size,
    double headerH,
    double dividerX,
    double margin,
    double availableH,
  ) {
    final rightStart = dividerX + margin;
    final rightEnd = size.width - margin;
    final goalSectionH = availableH * 0.4;
    final goalDividerY = headerH + goalSectionH;

    drawDividerLine(canvas, goalDividerY, rightStart, rightEnd);

    final checkboxSize = min(size.width, size.height) * 0.025;
    final goalLineH = goalSectionH / 6;
    for (var i = 0; i < 5; i++) {
      final y = headerH + margin + (i * goalLineH);
      drawCheckboxRect(
          canvas, Offset(rightStart, y + goalLineH * 0.2), checkboxSize);
      final lineY = y + goalLineH * 0.5 + checkboxSize * 0.5;
      canvas.drawLine(
        Offset(rightStart + checkboxSize + margin, lineY),
        Offset(rightEnd, lineY),
        accent.hair4,
      );
    }

    // Right bottom: note lines
    for (var y = goalDividerY + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(Offset(rightStart, y), Offset(rightEnd, y), accent.soft5);
    }
  }

  void drawWeeklyPlanner(Canvas canvas, Size size) {
    final margin = size.width * 0.03;
    final headerH = size.height * 0.06;
    final footerH = size.height * 0.15;

    drawDividerLine(canvas, headerH, margin, size.width - margin);
    drawDividerLine(canvas, size.height - footerH, margin, size.width - margin);

    // 7 day columns
    const dayCount = 7;
    final dayW = (size.width - margin * 2) / dayCount;
    for (var i = 1; i < dayCount; i++) {
      final x = margin + (i * dayW);
      canvas.drawLine(
          Offset(x, headerH), Offset(x, size.height - footerH), accent.ink);
    }

    // Horizontal lines inside the day area
    for (var y = headerH + spacingPx;
        y < size.height - footerH;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), accent.hair4);
    }

    // Footer: note lines
    for (var y = size.height - footerH + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), accent.hair5);
    }
  }

  void drawMonthlyPlanner(Canvas canvas, Size size) {
    final margin = size.width * 0.03;
    final headerH = size.height * 0.08;
    final footerH = size.height * 0.12;
    final gridH = size.height - headerH - footerH;
    final cols = (extraData?['gridCols'] as int?) ?? 7;
    final rows = (extraData?['gridRows'] as int?) ?? 6;

    drawDividerLine(canvas, headerH, margin, size.width - margin);
    drawDividerLine(canvas, size.height - footerH, margin, size.width - margin);

    final cellW = (size.width - margin * 2) / cols;
    final cellH = gridH / rows;

    for (var i = 0; i <= cols; i++) {
      final x = margin + (i * cellW);
      canvas.drawLine(
          Offset(x, headerH), Offset(x, size.height - footerH), accent.ink);
    }
    for (var i = 0; i <= rows; i++) {
      final y = headerH + (i * cellH);
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), accent.ink);
    }

    // Footer: note lines
    for (var y = size.height - footerH + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), accent.hair5);
    }
  }
}
