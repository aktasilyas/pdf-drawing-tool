import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts canvas calls by method name; draws nothing.
class _CountingCanvas implements Canvas {
  final counts = <String, int>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    counts[name] = (counts[name] ?? 0) + 1;
    return null;
  }
}

Map<String, int> _paint(TemplatePattern pattern, Size size,
    {Map<String, dynamic>? extraData}) {
  final canvas = _CountingCanvas();
  TemplatePatternPainter(
    pattern: pattern,
    spacingMm: pattern.defaultSpacingMm,
    lineWidth: pattern.defaultLineWidth,
    lineColor: const Color(0xFF444444),
    backgroundColor: const Color(0xFFFFFFFF),
    pageSize: size,
    extraData: extraData,
  ).paint(canvas, size);
  return canvas.counts;
}

int _count(Map<String, int> c, String method) => c['Symbol("$method")'] ?? 0;

void main() {
  const sizes = [Size(595, 842), Size(375, 667)];
  const patterns = [
    TemplatePattern.dailyPlanner,
    TemplatePattern.weeklyPlanner,
    TemplatePattern.monthlyPlanner,
    TemplatePattern.todoList,
    TemplatePattern.checklist,
    TemplatePattern.meetingNotes,
    TemplatePattern.bulletJournal,
    TemplatePattern.gratitudeJournal,
    TemplatePattern.storyboard,
    TemplatePattern.wireframe,
  ];

  for (final pattern in patterns) {
    for (final size in sizes) {
      test(
          '${pattern.name} paints lines at ${size.width.toInt()}x'
          '${size.height.toInt()}', () {
        final counts = _paint(pattern, size);
        expect(_count(counts, 'drawLine') + _count(counts, 'drawRRect'),
            greaterThan(5));
      });
    }
  }

  test('daily planner draws five goal checkboxes', () {
    final c = _paint(TemplatePattern.dailyPlanner, sizes.first);
    expect(_count(c, 'drawRRect'), 5);
  });

  test('storyboard draws one frame per framesPerPage cell', () {
    final c = _paint(TemplatePattern.storyboard, sizes.first,
        extraData: {'framesPerPage': 4});
    expect(_count(c, 'drawRRect'), 4);
  });

  test('wireframe draws one device per frame', () {
    final c = _paint(TemplatePattern.wireframe, sizes.first,
        extraData: {'framesPerPage': 2});
    expect(_count(c, 'drawRRect'), 2);
  });

  test('gratitude journal draws a prompt dot per prompt and 5 mood circles',
      () {
    final c = _paint(TemplatePattern.gratitudeJournal, sizes.first,
        extraData: {'promptCount': 4});
    expect(_count(c, 'drawCircle'), 4 + 5);
  });

  test('checklist draws a checkbox per row', () {
    final size = sizes.first;
    final spacing = TemplatePattern.checklist.defaultSpacingMm * 72 / 25.4;
    var rows = 0;
    for (var y = size.height * 0.06 + spacing;
        y < size.height - size.width * 0.05;
        y += spacing) {
      rows++;
    }
    final c = _paint(TemplatePattern.checklist, size);
    expect(_count(c, 'drawRRect'), rows);
  });

  test('bullet journal dot grid adds circles', () {
    final plain = _paint(TemplatePattern.bulletJournal, sizes.first);
    final grid = _paint(TemplatePattern.bulletJournal, sizes.first,
        extraData: {'dotGrid': true});
    expect(
        _count(grid, 'drawCircle'), greaterThan(_count(plain, 'drawCircle')));
  });
}
