import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('PageManager', () {
    group('Constructor', () {
      test('should create with default page', () {
        final manager = PageManager();

        expect(manager.pages.length, 1);
        expect(manager.currentIndex, 0);
        expect(manager.pageCount, 1);
      });

      test('should create with provided pages', () {
        final pages = [
          Page.create(index: 0),
          Page.create(index: 1),
        ];
        final manager = PageManager(pages: pages, currentIndex: 1);

        expect(manager.pages.length, 2);
        expect(manager.currentIndex, 1);
        expect(manager.pageCount, 2);
      });

      test('should return unmodifiable list', () {
        final manager = PageManager();

        expect(() => (manager.pages as List).add(Page.create(index: 1)),
            throwsUnsupportedError);
      });
    });

    group('Getters', () {
      test('currentPage returns page at current index', () {
        final page1 = Page.create(index: 0);
        final page2 = Page.create(index: 1);
        final manager = PageManager(pages: [page1, page2], currentIndex: 1);

        expect(manager.currentPage, page2);
      });

      test('canGoNext returns true when not at last page', () {
        final manager = PageManager(
          pages: [Page.create(index: 0), Page.create(index: 1)],
          currentIndex: 0,
        );

        expect(manager.canGoNext, true);
      });

      test('canGoNext returns false when at last page', () {
        final manager = PageManager(
          pages: [Page.create(index: 0), Page.create(index: 1)],
          currentIndex: 1,
        );

        expect(manager.canGoNext, false);
      });

      test('canGoPrevious returns true when not at first page', () {
        final manager = PageManager(
          pages: [Page.create(index: 0), Page.create(index: 1)],
          currentIndex: 1,
        );

        expect(manager.canGoPrevious, true);
      });

      test('canGoPrevious returns false when at first page', () {
        final manager = PageManager(
          pages: [Page.create(index: 0), Page.create(index: 1)],
          currentIndex: 0,
        );

        expect(manager.canGoPrevious, false);
      });
    });

    group('Navigation', () {
      test('goToPage changes current index', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
        );

        manager.goToPage(2);

        expect(manager.currentIndex, 2);
        expect(manager.currentPage.index, 2);
      });

      test('goToPage throws on invalid index', () {
        final manager = PageManager();

        expect(() => manager.goToPage(-1), throwsRangeError);
        expect(() => manager.goToPage(5), throwsRangeError);
      });

      test('nextPage moves to next page', () {
        final manager = PageManager(
          pages: [Page.create(index: 0), Page.create(index: 1)],
        );

        manager.nextPage();

        expect(manager.currentIndex, 1);
      });

      test('nextPage does nothing when at last page', () {
        final manager = PageManager(
          pages: [Page.create(index: 0), Page.create(index: 1)],
          currentIndex: 1,
        );

        manager.nextPage();

        expect(manager.currentIndex, 1);
      });

      test('previousPage moves to previous page', () {
        final manager = PageManager(
          pages: [Page.create(index: 0), Page.create(index: 1)],
          currentIndex: 1,
        );

        manager.previousPage();

        expect(manager.currentIndex, 0);
      });

      test('previousPage does nothing when at first page', () {
        final manager = PageManager();

        manager.previousPage();

        expect(manager.currentIndex, 0);
      });
    });

    group('CRUD Operations', () {
      test('addPage adds new page at end', () {
        final manager = PageManager();

        final newPage = manager.addPage();

        expect(manager.pageCount, 2);
        expect(newPage.index, 1);
        expect(manager.pages.last, newPage);
      });

      test('addPage with custom size and background', () {
        final manager = PageManager();

        final newPage = manager.addPage(
          size: PageSize.letterPortrait,
          background: PageBackground.grid,
        );

        expect(newPage.size, PageSize.letterPortrait);
        expect(newPage.background, PageBackground.grid);
      });

      test('insertPage inserts at specific index', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
          ],
        );

        final insertedPage = manager.insertPage(1);

        expect(manager.pageCount, 3);
        expect(manager.pages[1], insertedPage);
        // Indices should be updated
        expect(manager.pages[0].index, 0);
        expect(manager.pages[1].index, 1);
        expect(manager.pages[2].index, 2);
      });

      test('insertPage at beginning', () {
        final manager = PageManager();

        final insertedPage = manager.insertPage(0);

        expect(manager.pageCount, 2);
        expect(manager.pages[0], insertedPage);
        expect(manager.pages[0].index, 0);
        expect(manager.pages[1].index, 1);
      });

      test('insertPage at end is same as addPage', () {
        final manager = PageManager();

        final insertedPage = manager.insertPage(1);

        expect(manager.pageCount, 2);
        expect(manager.pages.last, insertedPage);
        expect(insertedPage.index, 1);
      });

      test('deletePage removes page at index', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
          currentIndex: 1,
        );

        manager.deletePage(1);

        expect(manager.pageCount, 2);
        // Indices should be updated
        expect(manager.pages[0].index, 0);
        expect(manager.pages[1].index, 1);
      });

      test('deletePage adjusts current index if deleting current page', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
          currentIndex: 1,
        );

        manager.deletePage(1);

        // Should stay at same position (which is now the next page)
        expect(manager.currentIndex, 1);
      });

      test('deletePage adjusts current index if deleting before current', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
          currentIndex: 2,
        );

        manager.deletePage(0);

        expect(manager.currentIndex, 1);
      });

      test('deletePage adjusts current index if deleting last page', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
          currentIndex: 2,
        );

        manager.deletePage(2);

        expect(manager.currentIndex, 1);
      });

      test('deletePage does not delete last page', () {
        final manager = PageManager();

        expect(() => manager.deletePage(0), throwsStateError);
        expect(manager.pageCount, 1);
      });

      test('duplicatePage creates copy of page', () {
        final stroke = Stroke.create(
          points: [DrawingPoint(x: 10, y: 20)],
          style: StrokeStyle.pen(),
        );
        final originalPage = Page.create(index: 0).addStroke(stroke);
        final manager = PageManager(pages: [originalPage]);

        manager.duplicatePage(0);

        expect(manager.pageCount, 2);
        expect(manager.pages[1].strokeCount, 1);
        expect(manager.pages[1].index, 1);
        // Should be a copy, not the same object
        expect(manager.pages[1] == manager.pages[0], false);
      });

      test('duplicatePage inserts after original', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
        );

        manager.duplicatePage(1);

        expect(manager.pageCount, 4);
        // Duplicate should be at index 2 (after original at 1)
        expect(manager.pages[2].index, 2);
        expect(manager.pages[3].index, 3);
      });

      test('reorderPage moves page to new position', () {
        final page0 = Page.create(index: 0);
        final page1 = Page.create(index: 1);
        final page2 = Page.create(index: 2);
        final manager = PageManager(pages: [page0, page1, page2]);

        manager.reorderPage(0, 2);

        expect(manager.pages[0], page1);
        expect(manager.pages[1], page2);
        expect(manager.pages[2], page0);
        // Indices should be updated
        expect(manager.pages[0].index, 0);
        expect(manager.pages[1].index, 1);
        expect(manager.pages[2].index, 2);
      });

      test('reorderPage adjusts current index when moving current page', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
          currentIndex: 0,
        );

        manager.reorderPage(0, 2);

        expect(manager.currentIndex, 2);
      });

      test('reorderPage adjusts current index when moving around current',
          () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
          currentIndex: 1,
        );

        manager.reorderPage(0, 2);

        // Current was at 1, page 0 moved to 2, so current should now be at 0
        expect(manager.currentIndex, 0);
      });
    });

    group('Update Operations', () {
      test('updatePage replaces page at index', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
          ],
        );
        final newPage = Page.create(
          index: 1,
          size: PageSize.letterPortrait,
        );

        manager.updatePage(1, newPage);

        expect(manager.pages[1], newPage);
        expect(manager.pages[1].size, PageSize.letterPortrait);
      });

      test('updatePage throws on invalid index', () {
        final manager = PageManager();
        final newPage = Page.create(index: 0);

        expect(() => manager.updatePage(-1, newPage), throwsRangeError);
        expect(() => manager.updatePage(5, newPage), throwsRangeError);
      });

      test('updateCurrentPage updates current page', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
          ],
          currentIndex: 1,
        );
        final newPage = Page.create(
          index: 1,
          size: PageSize.letterPortrait,
        );

        manager.updateCurrentPage(newPage);

        expect(manager.currentPage, newPage);
        expect(manager.currentPage.size, PageSize.letterPortrait);
      });
    });

    group('Edge Cases', () {
      test('handles empty pages list by creating default', () {
        final manager = PageManager(pages: []);

        expect(manager.pageCount, 1);
        expect(manager.currentIndex, 0);
      });

      test('handles out of bounds current index', () {
        final manager = PageManager(
          pages: [Page.create(index: 0)],
          currentIndex: 5,
        );

        // Should clamp to valid range
        expect(manager.currentIndex, 0);
      });

      test('reorderPage with same oldIndex and newIndex does nothing', () {
        final page0 = Page.create(index: 0);
        final page1 = Page.create(index: 1);
        final manager = PageManager(pages: [page0, page1]);

        manager.reorderPage(1, 1);

        expect(manager.pages[0], page0);
        expect(manager.pages[1], page1);
      });
    });
  });
}
