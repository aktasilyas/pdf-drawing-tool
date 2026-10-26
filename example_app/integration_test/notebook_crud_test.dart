import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';

void main() {
  initE2E();

  testWidgets(
    'notebook: create, survive an editor round trip, rename, favourite, '
    'trash and restore',
    (tester) async {
      const title = 'E2E Defter';
      const renamed = 'E2E Defter 2';

      await launchApp(tester);
      final library = LibraryRobot(tester);
      final editor = EditorRobot(tester);
      await library.waitForLibrary();
      library.expectEmptyState();

      // Create through the real UI; the app opens the editor.
      await library.createNotebook(title);
      await editor.waitForEditor();

      // Editor round trip: the notebook is still listed afterwards.
      await editor.goHome();
      await library.waitForLibrary();
      await library.waitListed(title);

      // Rename.
      await library.rename(title, renamed);
      await library.waitListed(renamed);
      library.expectNotListed(title);

      // Favourite: badge in the library, listed under Favoriler.
      await library.addToFavorites(renamed);
      await tester.pumpFor(const Duration(seconds: 1));
      library.expectFavoriteBadge(visible: true);
      await library.openSection(LibrarySection.favorites);
      await library.waitListed(renamed);
      await library.openSection(LibrarySection.all);
      await library.waitListed(renamed);

      // Trash: gone from the library, present in the trash.
      await library.moveToTrash(renamed);
      await library.waitNotListed(renamed);
      library.expectEmptyState();
      await library.openSection(LibrarySection.trash);
      await library.waitListed(renamed);

      // Restore: back in the library.
      await library.restore(renamed);
      await library.waitNotListed(renamed);
      await library.openSection(LibrarySection.all);
      await library.waitListed(renamed);
    },
  );
}
