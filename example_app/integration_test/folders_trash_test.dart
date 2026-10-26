import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/pump_helpers.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';

void main() {
  initE2E();

  testWidgets(
    'folders: create, subfolder, rename, delete and relaunch',
    (tester) async {
      await launchApp(tester);
      final library = LibraryRobot(tester);
      await library.waitForLibrary();

      await library.openManageFolders();
      await library.createFolder('E2E Klasör');
      library.expectFolderListed('E2E Klasör', listed: true);

      await library.addSubfolder('E2E Klasör', 'E2E Alt');
      library.expectFolderListed('E2E Alt', listed: true);

      await library.renameFolder('E2E Klasör', 'E2E Klasör 2');
      library.expectFolderListed('E2E Klasör 2', listed: true);
      library.expectFolderListed('E2E Klasör', listed: false);

      // Folders are read back from the database after a relaunch.
      await library.closeManageFolders();
      await relaunchApp(tester);
      await library.waitForLibrary();
      await library.openManageFolders();
      library.expectFolderListed('E2E Klasör 2', listed: true);

      await library.deleteFolder('E2E Klasör 2');
      await tester.pumpFor(const Duration(seconds: 1));
      library.expectFolderListed('E2E Klasör 2', listed: false);
    },
  );

  testWidgets(
    'trash: emptying purges trashed notebooks for good',
    (tester) async {
      const title = 'E2E Silinecek';
      await launchApp(tester);
      final library = LibraryRobot(tester);
      final editor = EditorRobot(tester);
      await library.waitForLibrary();

      await library.createNotebook(title);
      await editor.waitForEditor();
      await editor.goHome();
      await library.waitForLibrary();
      await library.waitListed(title);

      await library.moveToTrash(title);
      await library.waitNotListed(title);
      await library.openSection(LibrarySection.trash);
      await library.waitListed(title);

      await library.emptyTrash();
      await library.waitNotListed(title);

      // Still gone after a relaunch, in the trash and in the library.
      await relaunchApp(tester);
      await library.waitForLibrary();
      library.expectNotListed(title);
      await library.openSection(LibrarySection.trash);
      library.expectNotListed(title);
    },
  );
}
