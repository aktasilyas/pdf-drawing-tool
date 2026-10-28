import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/hardcoded_strings.dart';

/// Directories (relative to `example_app`) whose user-facing copy must come
/// from `AppLocalizations`. Later l10n slices add their directories here.
const migratedDirs = [
  'lib/features/settings/presentation',
  'lib/features/documents/presentation',
  'lib/core/widgets/feedback',
];

const _documents = 'lib/features/documents/presentation';

/// Files of [migratedDirs] whose literals are not migrated yet (#201 library
/// slice). Each step of `docs/plans/201-l10n-library.md` removes the files it
/// migrates; the set must be empty after step 6 and is then deleted.
const pendingL10n = <String>{
  '$_documents/screens/manage_folders_screen.dart',
  '$_documents/widgets/manage_folder_list_item.dart',
  '$_documents/widgets/move_to_folder_create_form.dart',
  '$_documents/widgets/move_to_folder_dialog.dart',
  '$_documents/widgets/move_to_folder_list.dart',
};

List<int> _lines(String source) =>
    findHardcodedStrings(source).map((f) => f.line).toList();

Map<String, String> _readArb(String name) {
  final raw = File('lib/l10n/$name').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)\}').allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  group('findHardcodedStrings', () {
    test('flags Turkish letters in any literal', () {
      expect(_lines("final a = 'Çıkış';"), [1]);
      expect(_lines('final a = "ağaç";'), [1]);
    });

    test('flags literals after Text( and copy arguments', () {
      const source = '''
Text('Settings');
Text(
  "Settings",
);
const Text('Hi');
Foo(title: 'Hi', subtitle: 'There', label: 'L', hintText: 'h');
Foo(labelText: 'l', message: 'm', tooltip: 't');
Foo(semanticsLabel: 's', semanticLabel: 's');
''';
      expect(_lines(source), [1, 3, 5, 6, 6, 6, 6, 7, 7, 7, 8, 8]);
    });

    test('ignores non-copy literals and non-literal arguments', () {
      const source = '''
final key = 'app_settings';
Foo(title: title, label: name);
Text(version ?? '—');
Text(AppAboutInfo.appName);
Image.asset('assets/images/a.png');
''';
      expect(_lines(source), isEmpty);
    });

    test('skips comments, directives and l10n-ignore lines', () {
      const source = '''
import 'package:example_app/çö.dart';
export 'a.dart';
// Text('Çıkış');
/// title: 'Çıkış'
/* Text('Çıkış') */
Text('PRO'), // l10n-ignore
final a = 1; // it's 'Çıkış'
''';
      expect(_lines(source), isEmpty);
    });

    test('skips empty and interpolation-only literals', () {
      const source = r'''
Text('');
Text('$count');
Text('${a} ${b.c}');
Text('${a} items');
''';
      expect(_lines(source), [4]);
    });

    test('handles quotes inside interpolation and raw strings', () {
      const source = r'''
final a = '${m['k']}';
final b = r'\d{2}';
Text('x' 'y');
''';
      expect(_lines(source), [3]);
    });
  });

  group('migrated directories', () {
    for (final dir in migratedDirs) {
      test('$dir has no hardcoded user-facing strings', () {
        final files = Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));
        expect(files, isNotEmpty);
        final offences = <String>[];
        for (final file in files) {
          if (pendingL10n.contains(file.path.replaceAll(r'\', '/'))) continue;
          final source = file.readAsStringSync();
          for (final f in findHardcodedStrings(source)) {
            offences.add('${file.path}:${f.line} "${f.literal}"');
          }
        }
        expect(
          offences,
          isEmpty,
          reason: 'Move to lib/l10n/*.arb or add // l10n-ignore',
        );
      });
    }
  });

  test('pendingL10n only lists files that still exist', () {
    for (final path in pendingL10n) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  group('ARB files', () {
    final en = _readArb('app_en.arb');
    final tr = _readArb('app_tr.arb');

    test('have the same keys', () {
      final enKeys = en.keys.toSet();
      final trKeys = tr.keys.toSet();
      expect(trKeys.difference(enKeys), isEmpty, reason: 'only in tr');
      expect(enKeys.difference(trKeys), isEmpty, reason: 'only in en');
    });

    test('have the same placeholders per key', () {
      for (final key in en.keys.where(tr.containsKey)) {
        expect(
          _placeholders(tr[key]!),
          _placeholders(en[key]!),
          reason: key,
        );
      }
    });

    test('have no empty values', () {
      for (final arb in [en, tr]) {
        for (final e in arb.entries) {
          expect(e.value.trim(), isNotEmpty, reason: e.key);
        }
      }
    });
  });
}
