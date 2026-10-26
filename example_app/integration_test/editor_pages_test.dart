import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/pump_helpers.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';
import 'robots/pages_robot.dart';

void main() {
  initE2E();

  testWidgets(
      'pages: add, reorder by drag, delete and undo, bookmark and filter '
      'in the page sidebar', (tester) async {
    await launchApp(tester);
    final library = LibraryRobot(tester);
    await library.waitForLibrary();
    await library.createNotebook('E2E Sayfalar', cover: false);
    await EditorRobot(tester).waitForEditor();

    final pages = PagesRobot(tester);
    expect(pages.pageIds(), hasLength(1));

    // Add two pages; each goes after the current page and becomes current.
    await pages.addPage();
    await pages.addPage();
    final ids = pages.pageIds();
    expect(ids, hasLength(3));
    expect(pages.currentIndex, 2);

    // Sidebar shows one cell per page.
    await pages.openSidebar();
    expect(pages.pageCells, findsNWidgets(3));

    // Long-press drag page 3 onto page 1.
    await pages.dragPage(from: 3, to: 1);
    final reordered = [ids[2], ids[0], ids[1]];
    await tester.pumpUntilTrue(
      () => _same(pages.pageIds(), reordered),
      reason: 'reorder: ${pages.pageIds()}, expected $reordered',
    );

    // Delete page 2 (no confirmation), then undo from the SnackBar.
    await pages.deletePage(2);
    await tester.pumpUntilTrue(
      () => _same(pages.pageIds(), [ids[2], ids[1]]),
      reason: 'delete: ${pages.pageIds()}',
    );
    await pages.undoDelete();
    await tester.pumpUntilTrue(
      () => _same(pages.pageIds(), reordered),
      reason: 'undo delete: ${pages.pageIds()}, expected $reordered',
    );

    // Bookmark the current page and find it under the bookmark filter.
    await pages.openSidebar();
    final current = pages.pageIds()[pages.currentIndex];
    await pages.bookmarkCurrentPage();
    await tester.pumpUntilTrue(
      () => pages.isBookmarked(current),
      reason: 'page $current not bookmarked',
    );
    await pages.showBookmarks();
    await tester.pumpUntilTrue(
      () => pages.pageCells.evaluate().length == 1,
      reason: 'bookmark filter shows '
          '${pages.pageCells.evaluate().length} cells, expected 1',
    );
    await pages.showAllPages();
    await tester.pumpUntilTrue(
      () => pages.pageCells.evaluate().length == 3,
      reason: 'all-pages filter shows '
          '${pages.pageCells.evaluate().length} cells, expected 3',
    );
  });
}

bool _same(List<String> a, List<String> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((e) => e);
