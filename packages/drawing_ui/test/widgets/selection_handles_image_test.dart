import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/selection_handles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Image at (100, 100) 200×100: centre (200, 150), rotation handle (200, 64).
const _img = ImageElement(
  id: 'i',
  filePath: 'a.png',
  x: 100,
  y: 100,
  width: 200,
  height: 100,
);

ImageElement _stored(ProviderContainer c) {
  final doc = c.read(documentProvider);
  return doc.layers[doc.activeLayerIndex].getImageById('i')!;
}

/// Adds [_img] to the document, selects it the way the selection tool does
/// and mounts [SelectionHandles] for the live selection.
Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(historyManagerProvider.notifier).execute(AddImageCommand(
        layerIndex: container.read(documentProvider).activeLayerIndex,
        imageElement: _img,
      ));
  container.read(selectionProvider.notifier).setSelection(Selection.create(
        type: SelectionType.rectangle,
        selectedStrokeIds: const [],
        selectedImageIds: const ['i'],
        bounds: _img.bounds,
      ));

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(builder: (context, ref, _) {
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
  testWidgets('body drag moves the image as one undo step', (tester) async {
    final c = await _pump(tester);
    await tester.dragFrom(const Offset(200, 150), const Offset(40, 30));
    await tester.pump();

    expect(_stored(c).x, 140);
    expect(_stored(c).y, 130);
    expect(c.read(historyManagerProvider).undoCount, 2); // add + move
    expect(c.read(selectionProvider)!.bounds,
        const BoundingBox(left: 140, top: 130, right: 340, bottom: 230));

    c.read(historyManagerProvider.notifier).undo();
    expect(_stored(c).x, 100);
    expect(_stored(c).y, 100);
  });

  testWidgets('corner drag scales the image as one undo step', (tester) async {
    final c = await _pump(tester);
    // Bottom-right corner (300, 200) → (400, 250): twice the distance from
    // the centre, so a uniform 2× scale around (200, 150).
    await tester.dragFrom(const Offset(300, 200), const Offset(100, 50));
    await tester.pump();

    expect(_stored(c).width, closeTo(400, 1e-6));
    expect(_stored(c).height, closeTo(200, 1e-6));
    expect(_stored(c).x, closeTo(0, 1e-6));
    expect(_stored(c).y, closeTo(50, 1e-6));
    expect(c.read(historyManagerProvider).undoCount, 2);

    c.read(historyManagerProvider.notifier).undo();
    expect(_stored(c).width, closeTo(200, 1e-6));
    expect(_stored(c).height, closeTo(100, 1e-6));
    expect(_stored(c).x, closeTo(100, 1e-6));
  });

  testWidgets('rotation handle drag rotates the image as one undo step',
      (tester) async {
    final c = await _pump(tester);
    // From straight above the centre to straight right of it: +90°.
    await tester.dragFrom(const Offset(200, 64), const Offset(100, 86));
    await tester.pump();

    expect(_stored(c).rotation, closeTo(math.pi / 2, 1e-6));
    expect(_stored(c).x, closeTo(100, 1e-6));
    expect(_stored(c).y, closeTo(100, 1e-6));
    expect(c.read(historyManagerProvider).undoCount, 2);

    c.read(historyManagerProvider.notifier).undo();
    expect(_stored(c).rotation, closeTo(0, 1e-6));
  });

  testWidgets('a corner is grabbable 23 screen px away at zoom 0.5',
      (tester) async {
    final c = await _pump(tester);
    c.read(canvasTransformProvider.notifier).setZoom(0.5);
    // 46 canvas units right of the bottom-right corner = 23 screen px.
    // The scale is measured from the corner itself, so ending at (400, 250)
    // is the same 2× scale as above.
    await tester.dragFrom(const Offset(346, 200), const Offset(54, 50));
    await tester.pump();

    expect(_stored(c).width, closeTo(400, 1e-6));
    expect(c.read(historyManagerProvider).undoCount, 2);
  });

  testWidgets('tap inside shows the menu, tap outside clears the selection',
      (tester) async {
    final c = await _pump(tester);
    await tester.tapAt(const Offset(160, 150));
    await tester.pump();
    expect(c.read(selectionUiProvider).showMenu, isTrue);

    await tester.tapAt(const Offset(600, 500));
    await tester.pump();
    expect(c.read(selectionProvider), isNull);
  });
}
