import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  Page page(String id, int index) => Page(
        id: id,
        index: index,
        size: PageSize.a4Portrait,
        layers: [Layer.empty('L')],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  void load(int count, {int current = 0}) {
    final doc = DrawingDocument.multiPage(
      id: 'd',
      title: 't',
      pages: [for (var i = 0; i < count; i++) page('p$i', i)],
      currentPageIndex: current,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    container.read(documentProvider.notifier).updateDocument(doc);
    container.read(pageManagerProvider.notifier).initializeFromDocument(
          doc.pages,
          currentIndex: current,
        );
  }

  List<String> docIds() =>
      container.read(documentProvider).pages.map((p) => p.id).toList();
  List<String> managerIds() =>
      container.read(pageManagerProvider).pages.map((p) => p.id).toList();
  PageStructureActions actions() =>
      container.read(pageStructureActionsProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('inserts all pages in order, renumbered, first one current', () {
    load(3, current: 0);
    actions().insertPages(1, [page('a', 0), page('b', 0)]);

    expect(docIds(), ['p0', 'a', 'b', 'p1', 'p2']);
    expect(managerIds(), docIds());
    final doc = container.read(documentProvider);
    expect([for (final p in doc.pages) p.index], [0, 1, 2, 3, 4]);
    expect(doc.currentPageIndex, 1);
    expect(container.read(pageManagerProvider).currentIndex, 1);
  });

  test('one undo removes every inserted page', () async {
    load(3, current: 2);
    final change = actions().insertPages(3, [page('a', 0), page('b', 0)]);

    expect(await actions().undo(change!), isTrue);
    expect(docIds(), ['p0', 'p1', 'p2']);
    final doc = container.read(documentProvider);
    expect(doc.pages[doc.currentPageIndex].id, 'p2');
  });

  test('clamps the index and returns null for no pages', () {
    load(2);
    expect(actions().insertPages(1, const []), isNull);
    expect(docIds(), ['p0', 'p1']);

    actions().insertPages(99, [page('a', 0)]);
    expect(docIds(), ['p0', 'p1', 'a']);
  });

  test('with a cover, inserting at 0 lands at 1 and undo restores order',
      () async {
    final doc = DrawingDocument.multiPage(
      id: 'd',
      title: 't',
      pages: [
        Page.createCover(index: 0, size: PageSize.a4Portrait),
        page('p1', 1),
        page('p2', 2),
      ],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    final coverId = doc.pages.first.id;
    container.read(documentProvider.notifier).updateDocument(doc);
    container.read(pageManagerProvider.notifier).initializeFromDocument(
          doc.pages,
          currentIndex: 0,
        );

    final change = actions().insertPages(0, [page('a', 0)]);

    expect(docIds(), [coverId, 'a', 'p1', 'p2']);
    expect(await actions().undo(change!), isTrue);
    expect(docIds(), [coverId, 'p1', 'p2']);
  });
}
