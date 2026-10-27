import 'package:drawing_core/drawing_core.dart'
    show BackgroundType, CoverRegistry, PageBackground, TemplateRegistry;
import 'package:drawing_ui/drawing_ui.dart' show documentProvider;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/expectations.dart';
import 'helpers/pump_helpers.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';
import 'robots/new_notebook_robot.dart';

/// A notebook with every pickable cover and every paper template opens in
/// the editor without errors.
///
/// The picker UI itself is driven in settings_test.dart (dark theme, one
/// non-default cover and template). Here the notebooks are created through
/// the app's documents controller and opened on the editor route, so the
/// 40+ notebooks fit in the e2e time budget. A notebook opens on its first
/// page: the cover when it has one, otherwise the paper page.
void main() {
  initE2E();

  testWidgets(
    'every cover and every paper template opens in the editor',
    (tester) async {
      await launchApp(tester);
      final library = LibraryRobot(tester);
      final editor = EditorRobot(tester);
      final notebooks = NewNotebookRobot(tester);
      await library.waitForLibrary();

      for (final cover in CoverRegistry.pickable) {
        final id = await notebooks.createAndOpen(
          'Kapak ${cover.id}',
          template: TemplateRegistry.blank,
          cover: cover,
        );
        await _waitLoaded(tester, editor, id);
        expect(_firstPage(editor).type, BackgroundType.cover);
        expect(_firstPage(editor).coverId, cover.id);
        expectNoErrorWidgets('cover ${cover.id}');
        await editor.goHome();
        await library.waitForLibrary();
      }

      for (final template in TemplateRegistry.all) {
        final id = await notebooks.createAndOpen(
          'Kağıt ${template.id}',
          template: template,
        );
        await _waitLoaded(tester, editor, id);
        final first = _firstPage(editor);
        expect(first.type, BackgroundType.template, reason: template.id);
        expect(first.templatePattern, template.pattern, reason: template.id);
        expectNoErrorWidgets('template ${template.id}');
        await editor.goHome();
        await library.waitForLibrary();
      }
    },
  );
}

/// Waits for the editor and for the notebook [id] to be its document
/// (the previous notebook's state may still be there for a few frames).
Future<void> _waitLoaded(
  WidgetTester tester,
  EditorRobot editor,
  String id,
) async {
  await editor.waitForEditor();
  await tester.pumpUntilTrue(
    () => editor.read(documentProvider).id == id,
    reason: 'notebook $id not loaded in the editor',
  );
  await tester.pumpFor(const Duration(milliseconds: 300));
}

/// Background of the open notebook's first page.
PageBackground _firstPage(EditorRobot editor) =>
    editor.read(documentProvider).pages.first.background;
