import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  Page page(String id, int index, int layers) => Page(
        id: id,
        index: index,
        size: PageSize.a4Portrait,
        layers: [for (var i = 0; i < layers; i++) Layer.empty('L$i')],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  Stroke stroke(String id) => Stroke(
        id: id,
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
        style: StrokeStyle.pen(),
        createdAt: DateTime(2024),
      );

  setUp(() {
    container = ProviderContainer();
    // Page p0 has two layers with the second active; p1 has a single layer.
    final doc = DrawingDocument.multiPage(
      id: 'd',
      title: 't',
      pages: [page('p0', 0, 2), page('p1', 1, 1)],
      currentPageIndex: 0,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ).copyWith(activeLayerIndex: 1);
    container.read(documentProvider.notifier).updateDocument(doc);
    container.read(pageManagerProvider.notifier).initializeFromDocument(
          doc.pages,
          currentIndex: 0,
        );
  });
  tearDown(() => container.dispose());

  test('active-layer providers do not throw after deleting the current page',
      () async {
    expect(container.read(documentProvider).activeLayerIndex, 1);

    await container.read(pageStructureActionsProvider).deletePage(0);

    final doc = container.read(documentProvider);
    expect(doc.pages.single.id, 'p1');
    expect(doc.activeLayerIndex, 0);
    expect(container.read(activeLayerTextsProvider), isEmpty);
    expect(container.read(activeLayerShapesProvider), isEmpty);
    expect(container.read(activeLayerImagesProvider), isEmpty);
  });

  test('a committed stroke lands on the new current page', () async {
    await container.read(pageStructureActionsProvider).deletePage(0);

    container.read(historyManagerProvider.notifier).execute(
          AddStrokeCommand(layerIndex: 0, stroke: stroke('s1')),
        );

    final doc = container.read(documentProvider);
    expect(doc.pages.single.layers.first.strokes.map((s) => s.id), ['s1']);
  });
}
