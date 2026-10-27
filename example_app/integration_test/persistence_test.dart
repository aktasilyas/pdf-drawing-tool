import 'package:drawing_ui/drawing_ui.dart' show documentProvider;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/pump_helpers.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';
import 'robots/pages_robot.dart';

/// Restart approach: `relaunchApp` unmounts the widget tree, closes the Drift
/// database and drops the GetIt registrations, then runs `AppBootstrap` again
/// on the same documents directory (database file and SharedPreferences are
/// not wiped). Everything shown afterwards is read back from disk, as after
/// a real process kill, without leaving the test.
void main() {
  initE2E();

  testWidgets(
    'persistence: notebook, pages and strokes survive an app relaunch',
    (tester) async {
      const title = 'E2E Kalıcılık';

      await launchApp(tester);
      final library = LibraryRobot(tester);
      final editor = EditorRobot(tester);
      final pages = PagesRobot(tester);
      await library.waitForLibrary();

      // No cover: cover pages do not keep drawings.
      await library.createNotebook(title, cover: false);
      await editor.waitForEditor();

      // One stroke on page 1, a second page with its own stroke.
      await editor.drawStroke(0.3);
      await pages.addPage();
      await editor.drawStroke(0.5);
      final saved = _strokesByPage(editor);
      expect(saved, hasLength(2));
      expect(saved.values.every((ids) => ids.length == 1), isTrue,
          reason: 'strokes per page before relaunch: $saved');

      // Home saves the notebook.
      await editor.goHome();
      await library.waitForLibrary();
      await library.waitListed(title);

      // Kill and reopen the app, then open the notebook again.
      await relaunchApp(tester);
      await library.waitForLibrary();
      await library.waitListed(title);
      await library.openNotebook(title);
      await editor.waitForEditor();

      await tester.pumpUntilTrue(
        () => _same(_strokesByPage(editor), saved),
        reason: 'after relaunch: ${_strokesByPage(editor)}, expected $saved',
      );
      expect(pages.pageIds(), saved.keys.toList());
    },
  );
}

/// Page id → stroke ids of all its layers, in page order.
Map<String, List<String>> _strokesByPage(EditorRobot editor) => {
      for (final page in editor.read(documentProvider).pages)
        page.id: [
          for (final layer in page.layers)
            for (final stroke in layer.strokes) stroke.id,
        ],
    };

bool _same(Map<String, List<String>> a, Map<String, List<String>> b) {
  if (a.length != b.length) return false;
  final aKeys = a.keys.toList();
  final bKeys = b.keys.toList();
  for (var i = 0; i < aKeys.length; i++) {
    if (aKeys[i] != bKeys[i]) return false;
    final x = a[aKeys[i]]!;
    final y = b[bKeys[i]]!;
    if (x.length != y.length || !x.toSet().containsAll(y)) return false;
  }
  return true;
}
