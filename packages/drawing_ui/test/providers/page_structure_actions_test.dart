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

  group('insertPage', () {
    test('inserts, selects the new page and syncs the page manager', () {
      load(3, current: 0);
      actions().insertPage(1, page('new', 0));

      expect(docIds(), ['p0', 'new', 'p1', 'p2']);
      expect(managerIds(), docIds());
      expect(container.read(documentProvider).currentPageIndex, 1);
      expect(container.read(pageManagerProvider).currentIndex, 1);
    });

    test('undo restores the page list and current page', () async {
      load(3, current: 2);
      final change = actions().insertPage(3, page('new', 0));

      expect(await actions().undo(change), isTrue);
      final doc = container.read(documentProvider);
      expect(docIds(), ['p0', 'p1', 'p2']);
      expect(managerIds(), docIds());
      expect(doc.currentPageIndex, 2);
      expect(doc.pages.map((p) => p.index), [0, 1, 2]);
    });

    test('undo keeps strokes drawn on other pages since the insert', () async {
      load(2, current: 0);
      final change = actions().insertPage(1, page('new', 0));
      container.read(historyManagerProvider.notifier).execute(
            AddStrokeCommand(layerIndex: 0, stroke: stroke('s1')),
            pageId: 'p0',
          );

      await actions().undo(change);
      expect(docIds(), ['p0', 'p1']);
      expect(container.read(documentProvider).pages[0].strokeCount, 1);
    });

    test('history entry on the removed page is a no-op on undo', () async {
      load(2, current: 0);
      container.read(pageTrashCallbackProvider.notifier).state =
          (i, p) async => 't1';
      final change = actions().insertPage(1, page('new', 0));
      container.read(historyManagerProvider.notifier).execute(
            AddStrokeCommand(layerIndex: 0, stroke: stroke('s1')),
          );
      await actions().undo(change);
      final before = container.read(documentProvider);

      container.read(historyManagerProvider.notifier).undo();
      expect(docIds(), ['p0', 'p1']);
      expect(container.read(documentProvider).pages[0].strokeCount,
          before.pages[0].strokeCount);
    });

    test('undo sends a page that gained ink to the page trash', () async {
      load(2, current: 0);
      final trashed = <Page>[];
      container.read(pageTrashCallbackProvider.notifier).state = (i, p) async {
        trashed.add(p);
        return 't1';
      };
      final change = actions().insertPage(1, page('new', 0));
      final doc = container.read(documentProvider);
      container.read(documentProvider.notifier).updateDocument(
            doc.replacePages([
              doc.pages[0],
              doc.pages[1].addStroke(stroke('s1')),
              doc.pages[2],
            ]),
          );

      expect(await actions().undo(change), isTrue);
      expect(docIds(), ['p0', 'p1']);
      expect(trashed.single.id, 'new');
      expect(trashed.single.strokeCount, 1);
    });

    Future<PageStructureChange> insertWithInk() async {
      load(2, current: 0);
      final change = actions().insertPage(1, page('new', 0));
      final doc = container.read(documentProvider);
      container.read(documentProvider.notifier).updateDocument(
            doc.replacePages([
              doc.pages[0],
              doc.pages[1].addStroke(stroke('s1')),
              doc.pages[2],
            ]),
          );
      return change;
    }

    test('undo keeps the page when it gained ink and there is no trash',
        () async {
      final change = await insertWithInk();

      expect(await actions().undo(change), isFalse);
      expect(docIds(), ['p0', 'new', 'p1']);
    });

    test('undo keeps the page when the trash cannot store it', () async {
      final change = await insertWithInk();
      container.read(pageTrashCallbackProvider.notifier).state =
          (i, p) async => null;

      expect(await actions().undo(change), isFalse);
      expect(docIds(), ['p0', 'new', 'p1']);
    });

    test('undo keeps the page when the trash throws', () async {
      final change = await insertWithInk();
      container.read(pageTrashCallbackProvider.notifier).state =
          (i, p) async => throw StateError('db');

      expect(await actions().undo(change), isFalse);
      expect(docIds(), ['p0', 'new', 'p1']);
    });

    test('undo discards the trash entry when the document changed meanwhile',
        () async {
      final change = await insertWithInk();
      final discarded = <String>[];
      container.read(pageTrashDiscardCallbackProvider.notifier).state =
          (id) async => discarded.add(id);
      container.read(pageTrashCallbackProvider.notifier).state = (i, p) async {
        final d = container.read(documentProvider);
        container
            .read(documentProvider.notifier)
            .updateDocument(d.removePage(0));
        return 't1';
      };

      expect(await actions().undo(change), isFalse);
      expect(discarded, ['t1']);
    });

    test('undo of an untouched page does not use the trash', () async {
      load(2, current: 0);
      var calls = 0;
      container.read(pageTrashCallbackProvider.notifier).state = (i, p) async {
        calls++;
        return 't1';
      };
      final change = actions().insertPage(1, page('new', 0));

      expect(await actions().undo(change), isTrue);
      expect(calls, 0);
      expect(docIds(), ['p0', 'p1']);
    });

    test('undo of an untouched duplicate does not use the trash', () async {
      load(2, current: 0);
      var calls = 0;
      container.read(pageTrashCallbackProvider.notifier).state = (i, p) async {
        calls++;
        return 't1';
      };
      final withInk = container.read(documentProvider).pages[0].addStroke(
            stroke('s1'),
          );
      final change = actions().insertCopy(0, withInk);

      expect(await actions().undo(change), isTrue);
      expect(calls, 0);
      expect(docIds(), ['p0', 'p1']);
    });

    /// Replaces page 1 (the inserted one) with [edit] of it.
    void editInserted(Layer Function(Layer) edit) {
      final doc = container.read(documentProvider);
      final inserted = doc.pages[1];
      container.read(documentProvider.notifier).updateDocument(
            doc.replacePages([
              doc.pages[0],
              inserted.copyWith(layers: [edit(inserted.layers.first)]),
              doc.pages[2],
            ]),
          );
    }

    test('undo sends an inserted page that got an image to the trash',
        () async {
      load(2, current: 0);
      final trashed = <Page>[];
      container.read(pageTrashCallbackProvider.notifier).state = (i, p) async {
        trashed.add(p);
        return 't1';
      };
      final change = actions().insertPage(1, page('new', 0));
      editInserted((l) => l.addImage(const ImageElement(
            id: 'img',
            filePath: 'a.png',
            x: 0,
            y: 0,
            width: 10,
            height: 10,
          )));

      expect(await actions().undo(change), isTrue);
      expect(docIds(), ['p0', 'p1']);
      expect(trashed.single.id, 'new');
    });

    test('undo sends an erased-and-redrawn duplicate to the trash', () async {
      load(2, current: 0);
      final trashed = <Page>[];
      container.read(pageTrashCallbackProvider.notifier).state = (i, p) async {
        trashed.add(p);
        return 't1';
      };
      final withInk = container.read(documentProvider).pages[0].addStroke(
            stroke('s1'),
          );
      final change = actions().insertCopy(0, withInk);
      editInserted((l) =>
          l.removeStroke(l.strokes.single.id).addStroke(stroke('s2')));

      expect(await actions().undo(change), isTrue);
      expect(docIds(), ['p0', 'p1']);
      expect(trashed.single.strokeCount, 1);
      expect(trashed.single.layers.first.strokes.single.id, 's2');
    });

    test('undo is a no-op after another page change', () async {
      load(3);
      final change = actions().insertPage(1, page('new', 0));
      await actions().deletePage(2);

      expect(await actions().undo(change), isFalse);
      expect(docIds(), ['p0', 'new', 'p2']);
    });

    test('undo is a no-op when another document is loaded', () async {
      load(2);
      final change = actions().insertPage(1, page('new', 0));
      container.read(documentProvider.notifier).updateDocument(
            DrawingDocument.multiPage(
              id: 'other',
              title: 't',
              pages: [page('x0', 0)],
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
            ),
          );

      expect(await actions().undo(change), isFalse);
      expect(docIds(), ['x0']);
    });
  });

  group('insertCopy', () {
    test('inserts a copy with fresh ids after the source and selects it', () {
      load(3, current: 0);
      final source = container.read(documentProvider).pages[1];
      final withInk = source.addStroke(stroke('s1'));

      actions().insertCopy(1, withInk);

      final doc = container.read(documentProvider);
      final copy = doc.pages[2];
      expect(doc.pages, hasLength(4));
      expect(doc.currentPageIndex, 2);
      expect(copy.id, isNot(withInk.id));
      expect(copy.layers.single.id, isNot(withInk.layers.single.id));
      expect(copy.layers.single.strokes.single.id, isNot('s1'));
      expect(copy.strokeCount, 1);
      expect(managerIds(), docIds());
    });

    test('undo removes the copy', () async {
      load(2, current: 1);
      final change =
          actions().insertCopy(0, container.read(documentProvider).pages[0]);

      await actions().undo(change);
      expect(docIds(), ['p0', 'p1']);
      expect(container.read(documentProvider).currentPageIndex, 1);
    });
  });

  group('movePage undo', () {
    test('returns null when nothing moved', () {
      load(3);
      expect(actions().movePage(1, 1), isNull);
    });

    test('undo restores the previous order and current page', () async {
      load(4, current: 1);
      final change = actions().movePage(3, 0)!;
      expect(docIds(), ['p3', 'p0', 'p1', 'p2']);

      expect(await actions().undo(change), isTrue);
      expect(docIds(), ['p0', 'p1', 'p2', 'p3']);
      expect(managerIds(), docIds());
      expect(container.read(documentProvider).currentPageIndex, 1);
    });
  });
}
