import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'template_accent_paints.dart';
import 'template_basic_painters.dart';
import 'template_journal_painters.dart';
import 'template_list_painters.dart';
import 'template_structural_helpers.dart';
import 'template_paints.dart';
import 'template_planner_painters.dart';
import 'template_writing_painters.dart';
import 'template_creative_painters.dart';
import 'template_table_painters.dart';

/// Template pattern'larını çizen base painter.
/// Tema renklerini dışarıdan alır, hardcoded renk kullanmaz.
class TemplatePatternPainter extends CustomPainter
    with
        TemplateStructuralHelpers,
        TemplateBasicPainters,
        TemplateWritingPainters,
        TemplatePlannerPainters,
        TemplateListPainters,
        TemplateJournalPainters,
        TemplateCreativePainters,
        TemplateTablePainters {
  final TemplatePattern pattern;
  final double spacingMm;
  final double lineWidth;
  final Color lineColor;
  final Color backgroundColor;
  final Size pageSize;
  final Map<String, dynamic>? extraData;

  // mm → px dönüşüm (72 DPI)
  @override
  double get spacingPx => spacingMm * 72 / 25.4;

  /// Public getter for mixin access
  @override
  Paint get linePaint => Paint()
    ..color = lineColor
    ..strokeWidth = lineWidth
    ..isAntiAlias = true;

  /// Paints built once per painter instance (never mutated).
  @override
  late final TemplatePaints paints = TemplatePaints(
    lineColor: lineColor,
    lineWidth: lineWidth,
    backgroundColor: backgroundColor,
  );

  /// Planner/creative paints, built once per painter instance.
  @override
  late final TemplateAccentPaints accent = TemplateAccentPaints(
    lineColor: lineColor,
    lineWidth: lineWidth,
  );

  TemplatePatternPainter({
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

  /// Builds a painter for a page background (transparent fill, the canvas
  /// paints the page color). [lineWidthScale] multiplies the line width (zoom).
  factory TemplatePatternPainter.fromBackground(
    PageBackground bg, {
    required Color lineColor,
    required Size pageSize,
    double lineWidthScale = 1,
  }) {
    assert(bg.templatePattern != null, 'templatePattern must not be null');
    return TemplatePatternPainter(
      pattern: bg.templatePattern!,
      spacingMm: bg.templateSpacingMm ?? 8.0,
      lineWidth: (bg.templateLineWidth ?? 0.5) * lineWidthScale,
      lineColor: lineColor,
      backgroundColor: Colors.transparent,
      pageSize: pageSize,
      extraData: bg.templateExtraData,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan
    canvas.drawRect(Offset.zero & size, paints.background);

    // Pattern çiz
    switch (pattern) {
      case TemplatePattern.blank:
        break;
      case TemplatePattern.thinLines:
      case TemplatePattern.mediumLines:
      case TemplatePattern.thickLines:
        drawLines(canvas, size);
        break;
      case TemplatePattern.smallGrid:
      case TemplatePattern.mediumGrid:
      case TemplatePattern.largeGrid:
        drawGrid(canvas, size);
        break;
      case TemplatePattern.smallDots:
      case TemplatePattern.mediumDots:
      case TemplatePattern.largeDots:
        drawDots(canvas, size);
        break;
      case TemplatePattern.isometric:
        drawIsometric(canvas, size);
        break;
      case TemplatePattern.hexagonal:
        drawHexagonal(canvas, size);
        break;
      case TemplatePattern.cornell:
        drawCornell(canvas, size);
        break;
      case TemplatePattern.music:
        drawMusic(canvas, size);
        break;
      case TemplatePattern.handwriting:
        drawHandwriting(canvas, size);
        break;
      case TemplatePattern.calligraphy:
        drawCalligraphy(canvas, size);
        break;

      // === YAPISAL PATTERN'LAR ===
      case TemplatePattern.dailyPlanner:
        drawDailyPlanner(canvas, size);
        break;
      case TemplatePattern.weeklyPlanner:
        drawWeeklyPlanner(canvas, size);
        break;
      case TemplatePattern.monthlyPlanner:
        drawMonthlyPlanner(canvas, size);
        break;
      case TemplatePattern.bulletJournal:
        drawBulletJournal(canvas, size);
        break;
      case TemplatePattern.gratitudeJournal:
        drawGratitudeJournal(canvas, size);
        break;
      case TemplatePattern.todoList:
        drawTodoList(canvas, size);
        break;
      case TemplatePattern.checklist:
        drawChecklist(canvas, size);
        break;
      case TemplatePattern.storyboard:
        drawStoryboard(canvas, size);
        break;
      case TemplatePattern.wireframe:
        drawWireframe(canvas, size);
        break;
      case TemplatePattern.meetingNotes:
        drawMeetingNotes(canvas, size);
        break;
      case TemplatePattern.readingLog:
        drawReadingLog(canvas, size);
        break;
      case TemplatePattern.vocabularyList:
        drawVocabularyList(canvas, size);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant TemplatePatternPainter oldDelegate) {
    return pattern != oldDelegate.pattern ||
        spacingMm != oldDelegate.spacingMm ||
        lineWidth != oldDelegate.lineWidth ||
        lineColor != oldDelegate.lineColor ||
        backgroundColor != oldDelegate.backgroundColor ||
        !mapEquals(extraData, oldDelegate.extraData);
  }
}
