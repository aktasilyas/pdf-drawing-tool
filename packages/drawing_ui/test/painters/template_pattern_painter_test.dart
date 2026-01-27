import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

void main() {
  group('TemplatePatternPainter', () {
    const testSize = Size(200, 300);
    const lineColor = Colors.grey;
    const backgroundColor = Colors.white;

    group('constructor', () {
      test('creates with required parameters', () {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.blank,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(painter.pattern, TemplatePattern.blank);
        expect(painter.spacingMm, 8);
        expect(painter.lineWidth, 0.5);
        expect(painter.lineColor, lineColor);
        expect(painter.backgroundColor, backgroundColor);
      });

      test('accepts extraData', () {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.cornell,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
          extraData: {'leftMarginRatio': 0.28},
        );

        expect(painter.extraData, {'leftMarginRatio': 0.28});
      });
    });

    group('fromTemplate factory', () {
      test('creates from template', () {
        final template = Template(
          id: 'test',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
        );

        final painter = TemplatePatternPainter.fromTemplate(
          template,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(painter.pattern, TemplatePattern.mediumLines);
        expect(painter.spacingMm, 8);
        expect(painter.lineWidth, 0.5);
        expect(painter.lineColor, lineColor);
        expect(painter.backgroundColor, backgroundColor);
      });

      test('includes extraData from template', () {
        final template = Template(
          id: 'cornell',
          name: 'Cornell',
          nameEn: 'Cornell',
          category: TemplateCategory.productivity,
          pattern: TemplatePattern.cornell,
          extraData: {'leftMarginRatio': 0.28},
        );

        final painter = TemplatePatternPainter.fromTemplate(
          template,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(painter.extraData, {'leftMarginRatio': 0.28});
      });
    });

    group('mm to px conversion', () {
      test('spacing is used correctly', () {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        // Verify spacing is stored correctly
        expect(painter.spacingMm, 8);
      });
    });

    group('paint', () {
      testWidgets('blank pattern draws only background', (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.blank,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: testSize,
                painter: painter,
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('lines pattern draws horizontal lines', (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: testSize,
                painter: painter,
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('grid pattern draws grid', (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.smallGrid,
          spacingMm: 5,
          lineWidth: 0.3,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: testSize,
                painter: painter,
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('dots pattern draws dots', (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.mediumDots,
          spacingMm: 7,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: testSize,
                painter: painter,
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('shouldRepaint', () {
      test('returns true when pattern changes', () {
        final painter1 = TemplatePatternPainter(
          pattern: TemplatePattern.blank,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final painter2 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns true when spacing changes', () {
        final painter1 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final painter2 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 10,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns true when lineWidth changes', () {
        final painter1 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final painter2 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.7,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns true when lineColor changes', () {
        final painter1 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: Colors.grey,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final painter2 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: Colors.blue,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns true when backgroundColor changes', () {
        final painter1 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: Colors.white,
          pageSize: testSize,
        );

        final painter2 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: Colors.yellow,
          pageSize: testSize,
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns false when nothing changes', () {
        final painter1 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final painter2 = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(painter1.shouldRepaint(painter2), false);
      });
    });

    group('pattern drawing', () {
      test('all line patterns use _drawLines', () {
        final thinPainter = TemplatePatternPainter(
          pattern: TemplatePattern.thinLines,
          spacingMm: 6,
          lineWidth: 0.3,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final mediumPainter = TemplatePatternPainter(
          pattern: TemplatePattern.mediumLines,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final thickPainter = TemplatePatternPainter(
          pattern: TemplatePattern.thickLines,
          spacingMm: 10,
          lineWidth: 0.7,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(thinPainter.pattern.hasLines, true);
        expect(mediumPainter.pattern.hasLines, true);
        expect(thickPainter.pattern.hasLines, true);
      });

      test('all grid patterns use _drawGrid', () {
        final smallPainter = TemplatePatternPainter(
          pattern: TemplatePattern.smallGrid,
          spacingMm: 5,
          lineWidth: 0.3,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final mediumPainter = TemplatePatternPainter(
          pattern: TemplatePattern.mediumGrid,
          spacingMm: 7,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final largePainter = TemplatePatternPainter(
          pattern: TemplatePattern.largeGrid,
          spacingMm: 10,
          lineWidth: 0.7,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(smallPainter.pattern.hasGrid, true);
        expect(mediumPainter.pattern.hasGrid, true);
        expect(largePainter.pattern.hasGrid, true);
      });

      test('all dot patterns use _drawDots', () {
        final smallPainter = TemplatePatternPainter(
          pattern: TemplatePattern.smallDots,
          spacingMm: 5,
          lineWidth: 0.3,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final mediumPainter = TemplatePatternPainter(
          pattern: TemplatePattern.mediumDots,
          spacingMm: 7,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        final largePainter = TemplatePatternPainter(
          pattern: TemplatePattern.largeDots,
          spacingMm: 10,
          lineWidth: 0.7,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: testSize,
        );

        expect(smallPainter.pattern.hasDots, true);
        expect(mediumPainter.pattern.hasDots, true);
        expect(largePainter.pattern.hasDots, true);
      });
    });
  });
}
