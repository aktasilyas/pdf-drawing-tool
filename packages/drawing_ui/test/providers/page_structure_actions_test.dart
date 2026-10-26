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

  Stroke stroke(String id) => Stroke(
        id: id,
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
        style: StrokeStyle.pen(),
        createdAt: DateTime(2024),
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

  group('movePage', () {
    test('updates document and page manager, keeps the current page', () {
      load(4, current: 1);
      actions().movePage(2, 0);

      expect(docIds(), ['p2', 'p0', 'p1', 'p3']);
      expect(managerIds(), docIds());
      final doc = container.read(documentProvider);
      expect(doc.pages[doc.currentPageIndex].id, 'p1');
      expect(container.read(pageManagerProvider).currentIndex,
          doc.currentPageIndex);
      expect(doc.pages.map((p) => p.index), [0, 1, 2, 3]);
    });

    test('out of range is a no-op', () {
      load(3);
      actions().movePage(0, 9);
      expect(docIds(), ['p0', 'p1', 'p2']);
    });

    test('history entry of a moved page still targets that page', () {
      load(3, current: 2);
      container.read(historyManagerProvider.notifier).execute(
            AddStrokeCommand(layerIndex: 0, stroke: stroke('s1')),
          );
      actions().movePage(2, 0);
      container.read(historyManagerProvider.notifier).undo();

      final doc = container.read(documentProvider);
      expect(doc.pages[0].id, 'p2');
      expect(doc.pages[0].strokeCount, 0);
    });
  });

  group('deletePage', () {
    test('returns null for the last page', () async {
      load(1);
      expect(await actions().deletePage(0), isNull);
      expect(docIds(), ['p0']);
    });

    test('removes the page, calls trash callback and records trash id',
        () async {
      load(3, current: 1);
      final calls = <(int, String)>[];
      container.read(pageTrashCallbackProvider.notifier).state =
          (index, page) async {
        calls.add((index, page.id));
        return 'trash-1';
      };

      final deleted = await actions().deletePage(1);

      expect(docIds(), ['p0', 'p2']);
      expect(managerIds(), ['p0', 'p2']);
      expect(calls, [(1, 'p1')]);
      expect(deleted!.page.id, 'p1');
      expect(deleted.index, 1);
      expect(deleted.wasCurrent, true);
      expect(deleted.trashId, 'trash-1');
    });

    test('works without a trash callback', () async {
      load(3);
      final deleted = await actions().deletePage(2);
      expect(docIds(), ['p0', 'p1']);
      expect(deleted!.trashId, isNull);
      expect(deleted.wasCurrent, false);
    });
  });

  group('deletePage edge cases', () {
    test('discards the trash entry when the page vanished during trashing',
        () async {
      load(3, current: 1);
      final discarded = <String>[];
      container.read(pageTrashCallbackProvider.notifier).state =
          (index, page) async {
        final doc = container.read(documentProvider);
        container
            .read(documentProvider.notifier)
            .updateDocument(doc.removePage(index));
        return 'trash-1';
      };
      container.read(pageTrashDiscardCallbackProvider.notifier).state =
          (id) async => discarded.add(id);

      expect(await actions().deletePage(1), isNull);
      expect(discarded, ['trash-1']);
    });

    test('null trash id still removes the page and undo works', () async {
      load(3, current: 1);
      final discarded = <String>[];
      container.read(pageTrashCallbackProvider.notifier).state =
          (_, __) async => null;
      container.read(pageTrashDiscardCallbackProvider.notifier).state =
          (id) async => discarded.add(id);

      final deleted = await actions().deletePage(1);
      expect(docIds(), ['p0', 'p2']);
      expect(deleted!.trashId, isNull);

      await actions().restorePage(deleted);
      expect(docIds(), ['p0', 'p1', 'p2']);
      expect(discarded, isEmpty);
    });
  });

  group('restorePage', () {
    test('no-op when a different document is loaded', () async {
      load(3, current: 1);
      final discarded = <String>[];
      container.read(pageTrashCallbackProvider.notifier).state =
          (_, __) async => 'trash-1';
      container.read(pageTrashDiscardCallbackProvider.notifier).state =
          (id) async => discarded.add(id);
      final deleted = await actions().deletePage(1);

      container.read(documentProvider.notifier).updateDocument(
            DrawingDocument.multiPage(
              id: 'other',
              title: 't',
              pages: [page('x0', 0), page('x1', 1)],
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
            ),
          );
      await actions().restorePage(deleted!);

      expect(docIds(), ['x0', 'x1']);
      expect(discarded, isEmpty);
    });

    test('puts the same page back, selects it, discards the trash entry',
        () async {
      load(3, current: 1);
      final discarded = <String>[];
      container.read(pageTrashCallbackProvider.notifier).state =
          (_, __) async => 'trash-1';
      container.read(pageTrashDiscardCallbackProvider.notifier).state =
          (id) async => discarded.add(id);
      final original = container.read(documentProvider).pages[1];

      final deleted = await actions().deletePage(1);
      await actions().restorePage(deleted!);

      final doc = container.read(documentProvider);
      expect(docIds(), ['p0', 'p1', 'p2']);
      expect(doc.pages[1], original);
      expect(doc.currentPageIndex, 1);
      expect(managerIds(), docIds());
      expect(container.read(pageManagerProvider).currentIndex, 1);
      expect(discarded, ['trash-1']);
    });

    test('keeps the current page when the deleted one was not current',
        () async {
      load(3, current: 0);
      final deleted = await actions().deletePage(2);
      await actions().restorePage(deleted!);
      expect(container.read(documentProvider).currentPageIndex, 0);
    });

    test('history of the restored page works again', () async {
      load(3, current: 2);
      container.read(historyManagerProvider.notifier).execute(
            AddStrokeCommand(layerIndex: 0, stroke: stroke('s1')),
          );
      final deleted = await actions().deletePage(2);
      await actions().restorePage(deleted!);

      container.read(historyManagerProvider.notifier).undo();
      expect(container.read(documentProvider).pages[2].strokeCount, 0);
    });
  });
}
