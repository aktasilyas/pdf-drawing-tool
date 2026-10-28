import 'package:drawing_core/drawing_core.dart'
    show TemplateCategory, TemplateRegistry;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/sticker_catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _EnTools extends ToolStringsTr {
  const _EnTools();

  @override
  String get fountainPen => 'Fountain pen';
}

class _EnStrings extends DrawingStringsTr {
  const _EnStrings();

  @override
  ToolStrings get tools => const _EnTools();
}

Future<DrawingStrings> _pump(
  WidgetTester tester, {
  DrawingStrings? scope,
}) async {
  late DrawingStrings seen;
  final probe = Builder(
    builder: (context) {
      seen = context.drawingStrings;
      return const SizedBox();
    },
  );
  await tester.pumpWidget(
    scope == null ? probe : DrawingStringsScope(strings: scope, child: probe),
  );
  return seen;
}

void main() {
  group('DrawingStringsScope', () {
    testWidgets('falls back to Turkish without a scope', (tester) async {
      final strings = await _pump(tester);
      expect(strings, isA<DrawingStringsTr>());
      expect(strings.toolbar.home, 'Ana Sayfa');
    });

    testWidgets('a scope overrides the fallback', (tester) async {
      final strings = await _pump(tester, scope: const _EnStrings());
      expect(strings, isA<_EnStrings>());
      expect(strings.tools.fountainPen, 'Fountain pen');
    });
  });

  group('DrawingStringsTr', () {
    const strings = DrawingStringsTr();

    test('every ToolType label is non-empty and distinct', () {
      final labels = [for (final t in ToolType.values) t.label(strings)];
      expect(labels, everyElement(isNotEmpty));
      expect(labels.toSet().length, labels.length);
    });

    test('tool strings map has no empty value', () {
      final map = strings.tools.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('toolbar strings map has no empty value', () {
      final map = strings.toolbar.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('panel strings map has no empty value', () {
      final map = strings.panels.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('catalog strings map has no empty value', () {
      final map = strings.catalog.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('selection strings map has no empty value', () {
      final map = strings.selection.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('pages strings map has no empty value', () {
      final map = strings.pages.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('pageList strings map has no empty value', () {
      final map = strings.pageList.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('export strings map has no empty value', () {
      final map = strings.export.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('templates strings map has no empty value', () {
      final map = strings.templates.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('errors strings map has no empty value', () {
      final map = strings.errors.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('canvas strings map has no empty value', () {
      final map = strings.canvas.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('toolbar color set names are present', () {
      final map = strings.toolbar.toMap();
      expect(map['colorSetBasic'], 'Temel');
      expect(map['colorSetNeon'], 'Neon');
    });

    test('duplicate keeps its Turkish characters', () {
      expect(strings.selection.duplicate, 'Çoğalt');
    });

    test('every ShapeType label is non-empty and distinct', () {
      final labels = [for (final t in ShapeType.values) t.label(strings)];
      expect(labels, everyElement(isNotEmpty));
      expect(labels.toSet().length, labels.length);
    });

    test('every StickerCategory label is non-empty and distinct', () {
      final labels = [for (final c in StickerCategory.values) c.label(strings)];
      expect(labels, everyElement(isNotEmpty));
      expect(labels.toSet().length, labels.length);
    });

    test('parameterized strings include their argument', () {
      expect(strings.toolbar.color('#FF0000'), contains('#FF0000'));
      expect(strings.toolbar.selectedColor('#FF0000'), contains('#FF0000'));
      expect(strings.toolbar.thickness('2.0'), contains('2.0'));
      expect(strings.pages.pageNumber(7), contains('7'));
      expect(
          strings.pageList.pageOf(3, 9), allOf(contains('3'), contains('9')));
      expect(strings.export.invalidRange(12), contains('12'));
      expect(strings.export.pageFileName('Notes', 4),
          allOf(contains('Notes'), contains('4')));
      expect(strings.errors.pdfTooManyPages(600, 500),
          allOf(contains('600'), contains('500')));
      expect(strings.canvas.penBox(5), contains('5'));
    });

    test('template and category names follow the Turkish model fields', () {
      expect(strings.templates.templateName(TemplateRegistry.blank),
          TemplateRegistry.blank.name);
      expect(strings.templates.categoryName(TemplateCategory.basic),
          TemplateCategory.basic.displayName);
    });
  });
}
