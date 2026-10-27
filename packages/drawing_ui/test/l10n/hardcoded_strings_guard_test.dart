import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/hardcoded_strings.dart';

/// Files and directories (relative to `packages/drawing_ui`) whose
/// user-facing copy must come from `DrawingStrings`. Later l10n slices add
/// their entries here.
const migrated = [
  'lib/src/toolbar',
  'lib/src/models/tool_type.dart',
  'lib/src/widgets/floating_undo_redo.dart',
  'lib/src/widgets/reorderable_tool_list.dart',
  'lib/src/panels/toolbar_settings_panel.dart',
];

/// The Turkish defaults live here by design.
const excluded = 'lib/src/l10n/';

List<int> _lines(String source) =>
    findHardcodedStrings(source).map((f) => f.line).toList();

Iterable<File> _dartFiles(String path) {
  if (FileSystemEntity.isFileSync(path)) return [File(path)];
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
}

void main() {
  group('findHardcodedStrings', () {
    test('flags Turkish letters and literals in copy positions', () {
      const source = '''
final a = 'Çıkış';
Text('Settings');
Foo(tooltip: 'Home');
''';
      expect(_lines(source), [1, 2, 3]);
    });

    test('ignores non-copy literals and l10n-ignore lines', () {
      const source = '''
final key = 'app_settings';
Foo(title: title);
Text('PRO'), // l10n-ignore
''';
      expect(_lines(source), isEmpty);
    });
  });

  group('migrated files', () {
    for (final path in migrated) {
      test('$path has no hardcoded user-facing strings', () {
        final files = _dartFiles(path).where(
          (f) => !f.path.replaceAll(r'\', '/').contains(excluded),
        );
        expect(files, isNotEmpty);
        final offences = <String>[];
        for (final file in files) {
          for (final f in findHardcodedStrings(file.readAsStringSync())) {
            offences.add('${file.path}:${f.line} "${f.literal}"');
          }
        }
        expect(
          offences,
          isEmpty,
          reason: 'Move to lib/src/l10n/ or add // l10n-ignore',
        );
      });
    }
  });
}
