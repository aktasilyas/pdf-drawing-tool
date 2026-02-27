import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

void main() {
  group('TemplatePatternPainter - Structural Patterns', () {
    const lineColor = Color(0xFFCCCCCC);
    const backgroundColor = Color(0xFFFFFFFF);
    const a4Size = Size(595, 842);

    group('all structural patterns render without error', () {
      final structuralPatterns = [
        TemplatePattern.dailyPlanner,
        TemplatePattern.weeklyPlanner,
        TemplatePattern.monthlyPlanner,
        TemplatePattern.bulletJournal,
        TemplatePattern.gratitudeJournal,
        TemplatePattern.todoList,
        TemplatePattern.checklist,
        TemplatePattern.storyboard,
        TemplatePattern.wireframe,
        TemplatePattern.meetingNotes,
        TemplatePattern.readingLog,
        TemplatePattern.vocabularyList,
      ];

      for (final pattern in structuralPatterns) {
        testWidgets('${pattern.name} renders without error', (tester) async {
          final painter = TemplatePatternPainter(
            pattern: pattern,
            spacingMm: pattern.defaultSpacingMm,
            lineWidth: pattern.defaultLineWidth,
            lineColor: lineColor,
            backgroundColor: backgroundColor,
            pageSize: a4Size,
            extraData: null,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  size: a4Size,
                  painter: painter,
                ),
              ),
            ),
          );

          expect(find.byType(CustomPaint), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }
    });

    group('responsive rendering', () {
      testWidgets('daily planner renders on small screen (phone)',
          (tester) async {
        const phoneSize = Size(375, 667);
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.dailyPlanner,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: phoneSize,
          extraData: {'startHour': 6, 'endHour': 22},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: phoneSize,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('weekly planner renders on tablet', (tester) async {
        const tabletSize = Size(1024, 1366);
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.weeklyPlanner,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: tabletSize,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: tabletSize,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('extraData configurations', () {
      testWidgets('storyboard renders with 16:9 aspect ratio',
          (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.storyboard,
          spacingMm: 0,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: a4Size,
          extraData: {'aspectRatio': '16:9', 'framesPerPage': 6},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: a4Size,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('storyboard renders with 4:3 aspect ratio',
          (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.storyboard,
          spacingMm: 0,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: a4Size,
          extraData: {'aspectRatio': '4:3', 'framesPerPage': 6},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: a4Size,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('vocabulary list uses custom column ratios',
          (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.vocabularyList,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: a4Size,
          extraData: {
            'columnRatios': [0.30, 0.30, 0.40],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: a4Size,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('monthly planner uses custom grid dimensions',
          (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.monthlyPlanner,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: a4Size,
          extraData: {'gridCols': 7, 'gridRows': 5},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: a4Size,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('bullet journal renders with dot grid enabled',
          (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.bulletJournal,
          spacingMm: 7,
          lineWidth: 0.3,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: a4Size,
          extraData: {'dotGrid': true},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: a4Size,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('wireframe renders tablet device type', (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.wireframe,
          spacingMm: 5,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: a4Size,
          extraData: {'deviceType': 'tablet', 'showGrid': true},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: a4Size,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('gratitude journal renders with mood scale disabled',
          (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.gratitudeJournal,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: a4Size,
          extraData: {'showMoodScale': false, 'promptCount': 5},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: a4Size,
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('structural pattern properties', () {
      test('all structural patterns are marked as isStructured', () {
        final structuralPatterns = [
          TemplatePattern.dailyPlanner,
          TemplatePattern.weeklyPlanner,
          TemplatePattern.monthlyPlanner,
          TemplatePattern.bulletJournal,
          TemplatePattern.gratitudeJournal,
          TemplatePattern.todoList,
          TemplatePattern.checklist,
          TemplatePattern.storyboard,
          TemplatePattern.wireframe,
          TemplatePattern.meetingNotes,
          TemplatePattern.readingLog,
          TemplatePattern.vocabularyList,
        ];

        for (final pattern in structuralPatterns) {
          expect(pattern.isStructured, true,
              reason: '${pattern.name} should be structured');
        }
      });

      test('all structural patterns have valid defaultSpacingMm', () {
        final structuralPatterns = [
          TemplatePattern.dailyPlanner,
          TemplatePattern.weeklyPlanner,
          TemplatePattern.monthlyPlanner,
          TemplatePattern.bulletJournal,
          TemplatePattern.gratitudeJournal,
          TemplatePattern.todoList,
          TemplatePattern.checklist,
          TemplatePattern.storyboard,
          TemplatePattern.wireframe,
          TemplatePattern.meetingNotes,
          TemplatePattern.readingLog,
          TemplatePattern.vocabularyList,
        ];

        for (final pattern in structuralPatterns) {
          expect(pattern.defaultSpacingMm, greaterThanOrEqualTo(0),
              reason: '${pattern.name} should have valid spacing');
        }
      });
    });
  });
}
