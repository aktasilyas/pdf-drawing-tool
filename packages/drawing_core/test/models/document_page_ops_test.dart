import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('DocumentPageOps', () {
    Page page(String id, int index) => Page(
          id: id,
          index: index,
          size: PageSize.a4Portrait,
          layers: [Layer.empty('L')],
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

    DrawingDocument fourPages({int current = 0}) => DrawingDocument.multiPage(
          id: 'd',
          title: 't',
          pages: [for (var i = 0; i < 4; i++) page('p$i', i)],
          currentPageIndex: current,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

    List<String> ids(DrawingDocument d) => d.pages.map((p) => p.id).toList();
    List<int> indexes(DrawingDocument d) =>
        d.pages.map((p) => p.index).toList();

    group('movePage', () {
      test('moves 2 -> 0 and re-numbers indexes', () {
        final doc = fourPages().movePage(2, 0);
        expect(ids(doc), ['p2', 'p0', 'p1', 'p3']);
        expect(indexes(doc), [0, 1, 2, 3]);
      });

      test('moves forward 0 -> 2', () {
        final doc = fourPages().movePage(0, 2);
        expect(ids(doc), ['p1', 'p2', 'p0', 'p3']);
        expect(indexes(doc), [0, 1, 2, 3]);
      });

      test('keeps the current page id', () {
        for (var cur = 0; cur < 4; cur++) {
          final before = fourPages(current: cur);
          final id = before.pages[cur].id;
          final after = before.movePage(2, 0);
          expect(after.pages[after.currentPageIndex].id, id);
        }
      });

      test('out of range or equal is a no-op', () {
        final doc = fourPages();
        expect(identical(doc.movePage(1, 1), doc), true);
        expect(identical(doc.movePage(-1, 2), doc), true);
        expect(identical(doc.movePage(1, 9), doc), true);
        expect(identical(doc.movePage(7, 1), doc), true);
      });

      test('keeps the Page object including background', () {
        final doc = fourPages();
        final moved = doc.movePage(3, 0);
        expect(moved.pages[0].background, doc.pages[3].background);
        expect(moved.pages[0].layers, doc.pages[3].layers);
      });

      test('toJson/fromJson keeps the new order', () {
        final doc = fourPages().movePage(2, 0);
        final restored = DrawingDocument.fromJson(doc.toJson());
        expect(ids(restored), ['p2', 'p0', 'p1', 'p3']);
        expect(indexes(restored), [0, 1, 2, 3]);
      });
    });

    group('insertPageAt', () {
      test('inserts at index, re-numbers, keeps current page id', () {
        final before = fourPages(current: 2);
        final doc = before.insertPageAt(1, page('x', 99));
        expect(ids(doc), ['p0', 'x', 'p1', 'p2', 'p3']);
        expect(indexes(doc), [0, 1, 2, 3, 4]);
        expect(doc.pages[doc.currentPageIndex].id, 'p2');
      });

      test('clamps the index', () {
        expect(ids(fourPages().insertPageAt(-5, page('x', 0))).first, 'x');
        expect(ids(fourPages().insertPageAt(50, page('x', 0))).last, 'x');
        expect(indexes(fourPages().insertPageAt(50, page('x', 0))),
            [0, 1, 2, 3, 4]);
      });
    });

    test('removePage re-numbers indexes', () {
      final doc = fourPages().removePage(1);
      expect(ids(doc), ['p0', 'p2', 'p3']);
      expect(indexes(doc), [0, 1, 2]);
    });
  });
}
