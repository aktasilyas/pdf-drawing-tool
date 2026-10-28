import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/providers/selection_edit_actions.dart';
import 'package:drawing_ui/src/widgets/selection_handles.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Selection must follow the document through undo/redo and page changes
// (issue #432).

Stroke _stroke(String id, double x, double y) => Stroke(
      id: id,
      points: [
        DrawingPoint(x: x, y: y),
        DrawingPoint(x: x + 100, y: y + 60),
      ],
      style: StrokeStyle.pen(),
      createdAt: DateTime(2026),
    );

BoundingBox _strokeBounds(ProviderContainer c, String id) {
  final doc = c.read(documentProvider);
  return doc.layers[doc.activeLayerIndex].getStrokeById(id)!.bounds!;
}

Selection _select(ProviderContainer c, List<String> ids) {
  final selection = Selection.create(
    type: SelectionType.lasso,
    selectedStrokeIds: ids,
    bounds: _strokeBounds(c, ids.first),
    lassoPath: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 1, y: 1)],
  );
  c.read(selectionProvider.notifier).setSelection(selection);
  return selection;
}

void _add(ProviderContainer c, Stroke s) =>
    c.read(historyManagerProvider.notifier).execute(AddStrokeCommand(
          layerIndex: c.read(documentProvider).activeLayerIndex,
          stroke: s,
        ));

/// Gives the document a second page and points the page manager at it,
/// staying on page 0.
void _twoPages(ProviderContainer c) {
  final notifier = c.read(documentProvider.notifier);
  final doc = c.read(documentProvider);
  notifier.updateDocument(doc.addPage(Page.create(index: 1)).setCurrentPage(0));
  final pages = c.read(documentProvider).pages;
  c.read(pageManagerProvider.notifier).initializeFromDocument(pages);
}

const _box = BoundingBox(left: 100, top: 100, right: 200, bottom: 160);

late WidgetRef _ref;

/// Mounts [SelectionHandles] for the live selection, like the canvas does.
Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(builder: (context, ref, _) {
          _ref = ref;
          final selection = ref.watch(selectionProvider);
          if (selection == null) return const SizedBox.expand();
          return SelectionHandles(selection: selection);
        }),
      ),
    ),
  ));
  return container;
}

void main() {
  testWidgets('move → undo puts the handles back around the original ink',
      (tester) async {
    final c = await _pump(tester);
    _add(c, _stroke('a', 100, 100));
    final original = _strokeBounds(c, 'a');
    _select(c, ['a']);
    await tester.pump();

    final centre = Offset(original.centerX, original.centerY);
    await tester.dragFrom(centre, const Offset(80, 40));
    await tester.pump();
    expect(_strokeBounds(c, 'a'), isNot(original));

    c.read(historyManagerProvider.notifier).undo();
    await tester.pump();
    expect(_strokeBounds(c, 'a'), original);
    expect(c.read(selectionProvider)!.bounds, original);
    expect(c.read(selectionProvider)!.selectedStrokeIds, ['a']);

    c.read(historyManagerProvider.notifier).redo();
    await tester.pump();
    expect(c.read(selectionProvider)!.bounds, _strokeBounds(c, 'a'));
    expect(c.read(selectionProvider)!.bounds, isNot(original));
  });

  testWidgets('undo that removes the selected ink clears selection and menu',
      (tester) async {
    final c = await _pump(tester);
    _add(c, _stroke('a', 100, 100));
    _select(c, ['a']);
    c.read(selectionUiProvider.notifier).showContextMenu();
    await tester.pump();

    c.read(historyManagerProvider.notifier).undo();
    await tester.pump();
    expect(c.read(selectionProvider), isNull);
    expect(c.read(selectionUiProvider).showMenu, isFalse);
    expect(find.byType(SelectionHandles), findsNothing);
  });

  testWidgets('undo drops vanished ids and shrinks the box to the rest',
      (tester) async {
    final c = await _pump(tester);
    _add(c, _stroke('a', 100, 100));
    _add(c, _stroke('b', 300, 300));
    final selection = _select(c, ['a', 'b']);
    c.read(selectionProvider.notifier).setSelection(selection.copyWith(
          bounds: const BoundingBox(left: 0, top: 0, right: 500, bottom: 500),
        ));

    c.read(historyManagerProvider.notifier).undo(); // removes 'b'
    final now = c.read(selectionProvider)!;
    expect(now.selectedStrokeIds, ['a']);
    expect(now.bounds, _strokeBounds(c, 'a'));
  });

  testWidgets('undo of an unrelated edit leaves the selection untouched',
      (tester) async {
    final c = await _pump(tester);
    _add(c, _stroke('a', 100, 100));
    final selection = _select(c, ['a']);
    _add(c, _stroke('b', 300, 300));

    c.read(historyManagerProvider.notifier).undo(); // removes 'b'
    expect(c.read(selectionProvider), same(selection));
  });

  testWidgets('changing the page clears the selection and its menu',
      (tester) async {
    final c = await _pump(tester);
    _twoPages(c);
    _add(c, _stroke('a', 100, 100));
    _select(c, ['a']);
    c.read(selectionUiProvider.notifier).showContextMenu();
    await tester.pump();

    c.read(pageManagerProvider.notifier).goToPage(1);
    await tester.pump();
    expect(c.read(selectionProvider), isNull);
    expect(c.read(selectionUiProvider).showMenu, isFalse);
    expect(find.byType(SelectionHandles), findsNothing);
  });

  testWidgets('a document page switch (e.g. undo navigating) clears it too',
      (tester) async {
    final c = await _pump(tester);
    final notifier = c.read(documentProvider.notifier);
    _twoPages(c);
    _add(c, _stroke('a', 100, 100));
    _select(c, ['a']);

    notifier.updateDocument(c.read(documentProvider).setCurrentPage(1));
    expect(c.read(selectionProvider), isNull);
  });

  testWidgets('delete with a stale selection records no history entry',
      (tester) async {
    final c = await _pump(tester);
    _add(c, _stroke('a', 100, 100));
    final stale = Selection.create(
      type: SelectionType.rectangle,
      selectedStrokeIds: const ['gone'],
      bounds: const BoundingBox(left: 0, top: 0, right: 10, bottom: 10),
    );
    c.read(selectionProvider.notifier).setSelection(stale);
    final before = c.read(historyManagerProvider).undoCount;

    deleteSelection(_ref, stale);
    duplicateSelection(_ref, stale);
    expect(c.read(historyManagerProvider).undoCount, before);
    expect(c.read(selectionProvider), isNull);
  });

  testWidgets('moving a stale selection records no history entry',
      (tester) async {
    final c = await _pump(tester);
    _add(c, _stroke('a', 100, 100));
    c.read(selectionProvider.notifier).setSelection(Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: const ['gone'],
          bounds: _box,
        ));
    await tester.pump();
    final before = c.read(historyManagerProvider).undoCount;

    await tester.dragFrom(const Offset(150, 130), const Offset(60, 30));
    await tester.pump();
    expect(c.read(historyManagerProvider).undoCount, before);
    expect(c.read(selectionProvider), isNull);
  });
}
