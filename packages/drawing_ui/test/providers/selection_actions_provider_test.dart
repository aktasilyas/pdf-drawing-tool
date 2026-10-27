import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/selection_action.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/feature_toggles_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/selection_actions_provider.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Stroke _stroke(String id) => Stroke(
      id: id,
      points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
      style: StrokeStyle.pen(),
      createdAt: DateTime(2026),
    );

Selection _select(List<String> ids) => Selection.create(
      type: SelectionType.rectangle,
      selectedStrokeIds: ids,
      bounds: const BoundingBox(left: 0, top: 0, right: 10, bottom: 10),
    );

void main() {
  late ProviderContainer container;
  late WidgetRef ref;

  Future<void> setUpRef(WidgetTester tester, {bool aiEnabled = true}) async {
    container = ProviderContainer(overrides: [
      aiAssistantEnabledProvider.overrideWithValue(aiEnabled),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Consumer(builder: (_, r, __) {
        ref = r;
        return const SizedBox();
      }),
    ));
    final notifier = container.read(documentProvider.notifier);
    for (final id in ['a', 'b', 'c']) {
      notifier.addStroke(_stroke(id));
    }
  }

  List<String> strokeIds() => container
      .read(documentProvider)
      .layers[0]
      .strokes
      .map((s) => s.id)
      .toList();

  SelectionAction find(SelectionActionConfig c, String id) => [
        ...c.toolbarActions,
        ...c.topRowActions,
        ...c.overflowActions,
      ].firstWhere((a) => a.id == id);

  /// Selects [ids], runs the action [actionId], returns the undo-count delta.
  int run(String actionId, List<String> ids) {
    final selection = _select(ids);
    container.read(selectionProvider.notifier).setSelection(selection);
    final before = container.read(undoCountProvider);
    find(buildSelectionActionConfig(ref, selection), actionId)
        .onExecute!
        .call();
    return container.read(undoCountProvider) - before;
  }

  /// Undo brings every element back at its original position (#260).
  void expectUndoRestores(List<String> expected) {
    container.read(historyManagerProvider.notifier).undo();
    expect(strokeIds(), expected);
  }

  testWidgets('delete is one undo step and clears selection', (tester) async {
    await setUpRef(tester);
    expect(run('delete', ['a', 'b']), 1);
    expect(strokeIds(), ['c']);
    expect(container.read(selectionProvider), isNull);
    expectUndoRestores(['a', 'b', 'c']);
  });

  testWidgets('duplicate is one undo step and clears selection',
      (tester) async {
    await setUpRef(tester);
    expect(run('duplicate', ['a', 'b']), 1);
    expect(strokeIds(), hasLength(5));
    expect(container.read(selectionProvider), isNull);
    expectUndoRestores(['a', 'b', 'c']);
  });

  testWidgets('copy fills the clipboard without touching history',
      (tester) async {
    await setUpRef(tester);
    expect(run('overflow_copy', ['a', 'b']), 0);
    expect(container.read(selectionClipboardProvider)!.strokes, hasLength(2));
    expect(strokeIds(), ['a', 'b', 'c']);
  });

  testWidgets('cut copies then deletes as one undo step', (tester) async {
    await setUpRef(tester);
    expect(run('cut', ['a']), 1);
    expect(container.read(selectionClipboardProvider)!.strokes.single.id, 'a');
    expect(strokeIds(), ['b', 'c']);
    expect(container.read(selectionProvider), isNull);
    expectUndoRestores(['a', 'b', 'c']);
  });

  testWidgets('bring to front is one undo step', (tester) async {
    await setUpRef(tester);
    expect(run('overflow_front', ['a']), 1);
    expect(strokeIds().last, 'a');
    expectUndoRestores(['a', 'b', 'c']);
  });

  testWidgets('send to back is one undo step', (tester) async {
    await setUpRef(tester);
    expect(run('overflow_back', ['c']), 1);
    expect(strokeIds().first, 'c');
    expectUndoRestores(['a', 'b', 'c']);
  });

  testWidgets('AI action is present when the AI flag is on', (tester) async {
    await setUpRef(tester);
    final c =
        buildSelectionActionConfig(ref, _select(['a']), onAIPressed: () {});
    expect(c.toolbarActions.map((a) => a.id), contains('ai'));
  });

  testWidgets('AI toolbar action is hidden when the AI flag is off',
      (tester) async {
    await setUpRef(tester, aiEnabled: false);
    final c =
        buildSelectionActionConfig(ref, _select(['a']), onAIPressed: () {});
    expect(c.toolbarActions.map((a) => a.id), isNot(contains('ai')));
    final empty =
        buildSelectionActionConfig(ref, Selection.empty(), onAIPressed: () {});
    expect(empty.toolbarActions.map((a) => a.id), isNot(contains('ai')));
  });
}
