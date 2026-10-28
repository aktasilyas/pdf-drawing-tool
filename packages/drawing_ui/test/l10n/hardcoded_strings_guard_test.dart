import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/hardcoded_strings.dart';

/// The Turkish defaults live here by design.
const excludedDir = 'lib/src/l10n/';

/// Frozen features (AI chat, audio recording) stay out of the v1.0 l10n
/// work until they are unfrozen.
const frozen = [
  'lib/src/panels/ai_assistant_panel.dart',
  'lib/src/panels/audio_recording_dropdown.dart',
  'lib/src/providers/audio_recording_provider.dart',
  'lib/src/screens/audio_recording_list_item.dart',
  'lib/src/screens/audio_recordings_list.dart',
  'lib/src/screens/audio_rename_dialog.dart',
  'lib/src/widgets/floating_recording_bar.dart',
];

String _normalized(String path) => path.replaceAll(r'\', '/');

bool _isExcluded(File file) {
  final path = _normalized(file.path);
  return path.startsWith(excludedDir) || frozen.contains(path);
}

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

  group('lib/src', () {
    test('excluded paths still exist', () {
      expect(Directory(excludedDir).existsSync(), isTrue, reason: excludedDir);
      for (final path in frozen) {
        expect(File(path).existsSync(), isTrue, reason: '$path is gone');
      }
    });

    test('has no hardcoded user-facing strings', () {
      final files = _dartFiles('lib/src').where((f) => !_isExcluded(f));
      expect(files, isNotEmpty);
      final offences = <String>[];
      for (final file in files) {
        for (final f in findHardcodedStrings(file.readAsStringSync())) {
          offences.add('${_normalized(file.path)}:${f.line} "${f.literal}"');
        }
      }
      expect(
        offences,
        isEmpty,
        reason: 'Move to lib/src/l10n/ or add // l10n-ignore',
      );
    });
  });
}
