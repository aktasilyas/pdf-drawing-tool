import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_resize_handles.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(historyManagerProvider.notifier).execute(AddImageCommand(
        layerIndex: container.read(documentProvider).activeLayerIndex,
        imageElement: _img,
      ));
  container.read(imagePlacementProvider.notifier).selectImage(_img);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(builder: (context, ref, _) {
          final selected = ref.watch(imagePlacementProvider).selectedImage;
          if (selected == null) return const SizedBox.expand();
          return SizedBox.expand(child: ImageResizeHandles(image: selected));
        }),
      ),
    ),
  ));
  return container;
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('body drag moves the image as one undo step', (tester) async {
    final c = await _pump(tester);
    await tester.dragFrom(const Offset(200, 150), const Offset(40, 30));
    await tester.pump();

    expect(_stored(c).x, 140);
    expect(_stored(c).y, 130);
    expect(c.read(historyManagerProvider).undoCount, 2); // add + move

    c.read(historyManagerProvider.notifier).undo();
    expect(_stored(c).x, 100);
    expect(_stored(c).y, 100);
  });

  testWidgets('corner drag resizes with a single command', (tester) async {
    final c = await _pump(tester);
    await tester.dragFrom(const Offset(300, 200), const Offset(60, 40));
    await tester.pump();

    expect(_stored(c).width, 260);
    expect(_stored(c).height, 140);
    expect(c.read(historyManagerProvider).undoCount, 2);

    c.read(historyManagerProvider.notifier).undo();
    expect(_stored(c).width, 200);
    expect(_stored(c).height, 100);
  });

  testWidgets('corner is grabbable at 23px from its centre', (tester) async {
    final c = await _pump(tester);
    await tester.dragFrom(const Offset(323, 200), const Offset(20, 0));
    await tester.pump();
    expect(_stored(c).width, 243); // corner follows the pointer
  });

  testWidgets('tap on body opens the menu, tap outside deselects',
      (tester) async {
    final c = await _pump(tester);
    c.read(imagePlacementProvider.notifier).hideContextMenu();
    await tester.pump();
    expect(c.read(imagePlacementProvider).showMenu, isFalse);

    await tester.tapAt(const Offset(200, 150));
    await tester.pump();
    expect(c.read(imagePlacementProvider).showMenu, isTrue);

    await tester.tapAt(const Offset(600, 500));
    await tester.pump();
    expect(c.read(imagePlacementProvider).selectedImage, isNull);
  });

  testWidgets('a drag that ends where it started records no command',
      (tester) async {
    final c = await _pump(tester);
    final g = await tester.startGesture(const Offset(200, 150));
    await g.moveBy(const Offset(30, 0));
    await g.moveBy(const Offset(-30, 0));
    await g.up();
    await tester.pump();

    expect(c.read(historyManagerProvider).undoCount, 1); // add only
  });
}
