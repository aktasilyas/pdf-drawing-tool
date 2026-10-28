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
  'lib/src/panels/pen_settings_panel.dart',
  'lib/src/panels/pen_type_picker.dart',
  'lib/src/panels/highlighter_settings_panel.dart',
  'lib/src/panels/eraser_settings_panel.dart',
  'lib/src/panels/eraser_settings_widgets.dart',
  'lib/src/panels/shapes_settings_panel.dart',
  'lib/src/panels/lasso_selection_panel.dart',
  'lib/src/panels/laser_pointer_panel.dart',
  'lib/src/panels/text_settings_panel.dart',
  'lib/src/panels/sticky_note_panel.dart',
  'lib/src/panels/sticker_panel.dart',
  'lib/src/panels/sticker_catalog.dart',
  'lib/src/widgets/color_picker_info_bar.dart',
  'lib/src/widgets/color_picker_actions.dart',
  'lib/src/widgets/compact_toggle.dart',
  'lib/src/widgets/text_context_menu.dart',
  'lib/src/widgets/paste_context_menu.dart',
  'lib/src/providers/selection_actions_provider.dart',
  'lib/src/providers/selection_capture_actions.dart',
  'lib/src/panels/chrome_panel_parts.dart',
  'lib/src/widgets/selection_toolbar.dart',
  'lib/src/widgets/selection_toolbar_buttons.dart',
  'lib/src/widgets/selection_overflow_menu.dart',
  'lib/src/widgets/compact_color_picker.dart',
  'lib/src/widgets/screenshot_preview_dialog.dart',
  'lib/src/widgets/color_presets.dart',
  'lib/src/widgets/selection_screenshot_feedback.dart',
  'lib/src/panels/sticker_panel_parts.dart',
  'lib/src/panels/sticker_panel_actions.dart',
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
