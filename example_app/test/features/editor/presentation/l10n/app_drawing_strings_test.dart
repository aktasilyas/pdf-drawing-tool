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

    test('parameterized strings carry their argument in $code', () {
      expect(strings.toolbar.selectedColor('#123456'), contains('#123456'));
      expect(strings.toolbar.color('#123456'), contains('#123456'));
      expect(strings.toolbar.thickness('2.5'), contains('2.5'));
    });
  }

  test('tr equals DrawingStringsTr, key sets included', () {
    final tr = AppDrawingStrings(lookupAppLocalizations(const Locale('tr')));
    expect(tr.tools.toMap(), fallback.tools.toMap());
    expect(tr.toolbar.toMap(), fallback.toolbar.toMap());
    expect(tr.panels.toMap(), fallback.panels.toMap());
    expect(tr.catalog.toMap(), fallback.catalog.toMap());
    expect(tr.selection.toMap(), fallback.selection.toMap());
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
