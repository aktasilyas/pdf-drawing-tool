import 'dart:math';
import 'dart:ui';

import 'template_structural_helpers.dart';

/// Mixin providing the journal template painters.
///
/// Contains: bulletJournal, gratitudeJournal.
/// All measurements proportional. All colors derive from lineColor.
mixin TemplateJournalPainters on TemplateStructuralHelpers {
  void drawBulletJournal(Canvas canvas, Size size) {
    final margin = size.width * 0.04;
    final headerH = size.height * 0.06;
    final bulletMargin = size.width * 0.08;

    drawDividerLine(canvas, headerH, margin, size.width - margin);

    // Left edge line (separates the bullet column)
    canvas.drawLine(
      Offset(bulletMargin, headerH),
      Offset(bulletMargin, size.height - margin),
      accent.soft3,
    );

    // Ruled lines + bullet dots
    final bulletR = min(size.width, size.height) * 0.005;
    for (var y = headerH + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
        Offset(bulletMargin + margin * 0.5, y),
        Offset(size.width - margin, y),
        accent.hair4,
      );
      final bulletY = y - spacingPx * 0.5;
      if (bulletY > headerH) {
        canvas.drawCircle(
            Offset(bulletMargin * 0.55, bulletY), bulletR, accent.bulletDot);
      }
    }

    if (extraData?['dotGrid'] == true) {
      _drawBulletDotGrid(canvas, size, headerH, bulletMargin, margin);
    }
  }

  void _drawBulletDotGrid(
    Canvas canvas,
    Size size,
    double headerH,
    double bulletMargin,
    double margin,
  ) {
    final dotSpacing = spacingPx * 0.5;
    final dotR = lineWidth * 0.5;
    for (var x = bulletMargin + dotSpacing;
        x < size.width - margin;
        x += dotSpacing) {
      for (var y = headerH + dotSpacing;
          y < size.height - margin;
          y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotR, accent.dotGrid);
      }
    }
  }

  void drawGratitudeJournal(Canvas canvas, Size size) {
    final margin = size.width * 0.05;
    final headerH = size.height * 0.08;
    final section1H = size.height * 0.25;
    final section2H = size.height * 0.35;

    final section1Y = headerH;
    final section2Y = section1Y + section1H;
    final section3Y = section2Y + section2H;

    drawDividerLine(canvas, headerH, margin, size.width - margin);
    drawDividerLine(canvas, section2Y, margin, size.width - margin);
    drawDividerLine(canvas, section3Y, margin, size.width - margin);

    // Section 1: prompt lines
    final promptCount = (extraData?['promptCount'] as int?) ?? 3;
    final promptLineH = section1H / (promptCount + 1);
    final dotR = min(size.width, size.height) * 0.008;
    for (var i = 1; i <= promptCount; i++) {
      final y = section1Y + (i * promptLineH);
      canvas.drawCircle(Offset(margin + dotR, y), dotR, accent.promptDot);
      canvas.drawLine(Offset(margin + dotR * 4, y),
          Offset(size.width - margin, y), accent.hair4);
    }

    // Section 2: free writing lines
    for (var y = section2Y + spacingPx;
        y < section3Y - margin * 0.5;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), accent.hair4);
    }

    _drawGratitudeMoodSection(canvas, size, section3Y, margin);
  }

  void _drawGratitudeMoodSection(
    Canvas canvas,
    Size size,
    double section3Y,
    double margin,
  ) {
    // Mood scale (5 circles)
    if (extraData?['showMoodScale'] != false) {
      final moodY = section3Y + (size.height - section3Y) * 0.4;
      const moodCount = 5;
      final moodSpacing = (size.width - margin * 4) / (moodCount - 1);
      final moodR = min(size.width, size.height) * 0.025;
      for (var i = 0; i < moodCount; i++) {
        final x = margin * 2 + (i * moodSpacing);
        canvas.drawCircle(Offset(x, moodY), moodR, accent.soft4);
      }
    }

    for (var y = section3Y + (size.height - section3Y) * 0.55;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), accent.hair4);
    }
  }
}
