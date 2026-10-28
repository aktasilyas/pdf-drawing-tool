import 'dart:math';
import 'dart:ui';

import 'template_structural_helpers.dart';

/// Mixin providing the list-style template painters.
///
/// Contains: todoList, checklist, meetingNotes.
/// All measurements proportional. All colors derive from lineColor.
mixin TemplateListPainters on TemplateStructuralHelpers {
  void drawTodoList(Canvas canvas, Size size) {
    final margin = size.width * 0.04;
    final headerH = size.height * 0.07;
    final priorityW = size.width * 0.06;
    final checkboxW = size.width * 0.06;
    final checkboxSize = min(size.width, size.height) * 0.022;
    final rowH = spacingPx * 1.2;

    drawDividerLine(canvas, headerH, margin, size.width - margin);

    // Vertical separators: priority | checkbox | content
    canvas.drawLine(
      Offset(margin + priorityW, headerH),
      Offset(margin + priorityW, size.height - margin),
      accent.hair3,
    );
    canvas.drawLine(
      Offset(margin + priorityW + checkboxW, headerH),
      Offset(margin + priorityW + checkboxW, size.height - margin),
      accent.hair3,
    );

    for (var y = headerH + rowH; y < size.height - margin; y += rowH) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), accent.hair3);
      final cbY = y - rowH * 0.5 - checkboxSize * 0.5;
      final cbX = margin + priorityW + (checkboxW - checkboxSize) * 0.5;
      drawCheckboxRect(canvas, Offset(cbX, cbY), checkboxSize);
    }
  }

  void drawChecklist(Canvas canvas, Size size) {
    final margin = size.width * 0.05;
    final headerH = size.height * 0.06;
    final checkboxSize = min(size.width, size.height) * 0.02;
    final checkboxMargin = size.width * 0.08;
    final rowH = spacingPx;

    drawDividerLine(canvas, headerH, margin, size.width - margin);

    for (var y = headerH + rowH; y < size.height - margin; y += rowH) {
      final cbY = y - rowH * 0.5 - checkboxSize * 0.5;
      drawCheckboxRect(canvas, Offset(margin, cbY), checkboxSize);
      canvas.drawLine(Offset(checkboxMargin, y), Offset(size.width - margin, y),
          accent.hair4);
    }
  }

  void drawMeetingNotes(Canvas canvas, Size size) {
    final margin = size.width * 0.05;
    final headerH = size.height * 0.08;
    final s1H = size.height * 0.15;
    final s2H = size.height * 0.15;
    final s4H = size.height * 0.20;

    final s1Y = headerH;
    final s2Y = s1Y + s1H;
    final s3Y = s2Y + s2H;
    final s4Y = size.height - s4H;

    for (final y in [s1Y, s2Y, s3Y, s4Y]) {
      drawDividerLine(canvas, y, margin, size.width - margin);
    }

    // Sections 1-3: ruled lines
    for (final bounds in [
      [s1Y, s2Y],
      [s2Y, s3Y],
      [s3Y, s4Y],
    ]) {
      for (var y = bounds[0] + spacingPx;
          y < bounds[1] - margin * 0.3;
          y += spacingPx) {
        canvas.drawLine(
            Offset(margin, y), Offset(size.width - margin, y), accent.hair4);
      }
    }

    // Section 4: action checkboxes
    final checkboxSize = min(size.width, size.height) * 0.02;
    final actionRowH = spacingPx * 1.2;
    for (var y = s4Y + actionRowH; y < size.height - margin; y += actionRowH) {
      drawCheckboxRect(
        canvas,
        Offset(margin, y - checkboxSize * 0.5 - actionRowH * 0.2),
        checkboxSize,
      );
      canvas.drawLine(
        Offset(margin + checkboxSize + margin * 0.5, y),
        Offset(size.width - margin, y),
        accent.hair4,
      );
    }
  }
}
