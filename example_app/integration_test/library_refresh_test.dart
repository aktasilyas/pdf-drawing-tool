import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';
import 'robots/pages_robot.dart';

void main() {
  initE2E();

  testWidgets(
    'library: a rename and a new page made in the editor show on the tile '
    'after going home, without a relaunch (#464)',
    (tester) async {
      const title = 'E2E Yenileme';
      const renamed = 'E2E Yenileme 2';

      await launchApp(tester);
      final library = LibraryRobot(tester);
      final editor = EditorRobot(tester);
      await library.waitForLibrary();
      await library.createNotebook(title, cover: false);
      await editor.waitForEditor();

      await editor.renameDocument(renamed);
      await PagesRobot(tester).addPage();

      await editor.goHome();
      await library.waitForLibrary();
      await library.waitListed(renamed);
      library.expectNotListed(title);
    },
  );
}
