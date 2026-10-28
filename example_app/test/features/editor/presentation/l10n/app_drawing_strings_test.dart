import 'package:drawing_core/drawing_core.dart'
    show TemplateCategory, TemplateRegistry;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/l10n/l10n.dart';

void main() {
  const locales = [Locale('en'), Locale('tr')];
  const fallback = DrawingStringsTr();

  for (final locale in locales) {
    final code = locale.languageCode;
    final strings = AppDrawingStrings(lookupAppLocalizations(locale));

    test('every tool name is non-empty and distinct in $code', () {
      for (final entry in strings.tools.toMap().entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
      final labels = [for (final t in ToolType.values) t.label(strings)];
      expect(labels.toSet(), hasLength(labels.length), reason: code);
    });

    test('every toolbar string is non-empty in $code', () {
      final map = strings.toolbar.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('every panel string is non-empty in $code', () {
      final map = strings.panels.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('every catalog string is non-empty in $code', () {
      final map = strings.catalog.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
      final shapes = [for (final t in ShapeType.values) t.label(strings)];
      expect(shapes.toSet(), hasLength(shapes.length), reason: code);
    });

    test('every selection string is non-empty in $code', () {
      final map = strings.selection.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('every page string is non-empty in $code', () {
      final map = strings.pages.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('every page list string is non-empty in $code', () {
      final map = strings.pageList.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('every export string is non-empty in $code', () {
      final map = strings.export.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('every template string is non-empty in $code', () {
      final map = strings.templates.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('every error string is non-empty in $code', () {
      final map = strings.errors.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('every canvas string is non-empty in $code', () {
      final map = strings.canvas.toMap();
      expect(map.keys, isNotEmpty);
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} ($code)');
      }
    });

    test('parameterized strings carry their argument in $code', () {
      expect(strings.toolbar.selectedColor('#123456'), contains('#123456'));
      expect(strings.toolbar.color('#123456'), contains('#123456'));
      expect(strings.toolbar.thickness('2.5'), contains('2.5'));
      expect(strings.pages.pageNumber(7), contains('7'));
      expect(strings.pageList.pageOf(3, 9),
          allOf(contains('3'), contains('9')));
      expect(strings.export.invalidRange(12), contains('12'));
      expect(strings.export.pageFileName('Notes', 4),
          allOf(contains('Notes'), contains('4')));
      expect(strings.errors.pdfTooManyPages(600, 500),
          allOf(contains('600'), contains('500')));
      expect(strings.canvas.penBox(5), contains('5'));
    });
  }

  test('tr equals DrawingStringsTr, key sets included', () {
    final tr = AppDrawingStrings(lookupAppLocalizations(const Locale('tr')));
    expect(tr.tools.toMap(), fallback.tools.toMap());
    expect(tr.toolbar.toMap(), fallback.toolbar.toMap());
    expect(tr.panels.toMap(), fallback.panels.toMap());
    expect(tr.catalog.toMap(), fallback.catalog.toMap());
    expect(tr.selection.toMap(), fallback.selection.toMap());
    expect(tr.pages.toMap(), fallback.pages.toMap());
    expect(tr.pageList.toMap(), fallback.pageList.toMap());
    expect(tr.export.toMap(), fallback.export.toMap());
    expect(tr.templates.toMap(), fallback.templates.toMap());
    expect(tr.errors.toMap(), fallback.errors.toMap());
    expect(tr.canvas.toMap(), fallback.canvas.toMap());
  });

  test('every en string is translated (differs from tr)', () {
    final en = AppDrawingStrings(lookupAppLocalizations(const Locale('en')));
    final tr = AppDrawingStrings(lookupAppLocalizations(const Locale('tr')));
    // Same word in both languages, per group.
    void check(
      String group,
      Map<String, String> enMap,
      Map<String, String> trMap, [
      Set<String> sameInBoth = const {},
    ]) {
      for (final key in enMap.keys.where((k) => !sameInBoth.contains(k))) {
        expect(enMap[key], isNot(trMap[key]), reason: '$group.$key');
      }
    }

    check('tools', en.tools.toMap(), tr.tools.toMap());
    check('toolbar', en.toolbar.toMap(), tr.toolbar.toMap(),
        {'colorSetPastel', 'colorSetNeon'});
    check('panels', en.panels.toMap(), tr.panels.toMap());
    check('catalog', en.catalog.toMap(), tr.catalog.toMap(), {'stickerEmoji'});
    check('selection', en.selection.toMap(), tr.selection.toMap());
    check('pages', en.pages.toMap(), tr.pages.toMap());
    check('pageList', en.pageList.toMap(), tr.pageList.toMap());
    check('export', en.export.toMap(), tr.export.toMap());
    check('templates', en.templates.toMap(), tr.templates.toMap());
    check('errors', en.errors.toMap(), tr.errors.toMap());
    check('canvas', en.canvas.toMap(), tr.canvas.toMap());
  });

  test('template and category names follow the locale', () {
    final en = AppDrawingStrings(lookupAppLocalizations(const Locale('en')));
    final tr = AppDrawingStrings(lookupAppLocalizations(const Locale('tr')));
    final blank = TemplateRegistry.blank;
    expect(en.templates.templateName(blank), blank.nameEn);
    expect(tr.templates.templateName(blank), blank.name);
    expect(en.templates.categoryName(TemplateCategory.basic),
        TemplateCategory.basic.displayNameEn);
    expect(tr.templates.categoryName(TemplateCategory.basic),
        TemplateCategory.basic.displayName);
  });

  test('equality follows the locale', () {
    final en1 = AppDrawingStrings(lookupAppLocalizations(const Locale('en')));
    final en2 = AppDrawingStrings(lookupAppLocalizations(const Locale('en')));
    final tr = AppDrawingStrings(lookupAppLocalizations(const Locale('tr')));
    expect(en1, en2);
    expect(en1.hashCode, en2.hashCode);
    expect(en1, isNot(tr));
  });
}
