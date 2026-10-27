import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/providers/providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  LayerActions actions() => container.read(layerActionsProvider);
  DrawingDocument doc() => container.read(documentProvider);
  int undoCount() => container.read(historyManagerProvider).undoCount;
  void undo() => container.read(historyManagerProvider.notifier).undo();
  void redo() => container.read(historyManagerProvider.notifier).redo();
  List<String> names() => doc().layers.map((l) => l.name).toList();

  group('LayerActions', () {
    test('add is one undo step and activates the new layer', () {
      final firstId = doc().layers.first.id;
      actions().add('Two');

      expect(undoCount(), 1);
      expect(doc().layers, hasLength(2));
      expect(doc().activeLayerIndex, 1);

      undo();
      expect(doc().layers.map((l) => l.id), [firstId]);
      expect(doc().activeLayerIndex, 0);

      redo();
      expect(doc().layers, hasLength(2));
      expect(doc().activeLayerIndex, 1);
    });

    test('remove is one undo step; undo restores layer with strokes', () {
      actions().add('Two');
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen())
                .addPoint(DrawingPoint(x: 1, y: 1)),
          );
      final removedId = doc().layers[1].id;
      final before = undoCount();

      actions().remove(1);
      expect(undoCount(), before + 1);
      expect(doc().layers, hasLength(1));

      undo();
      expect(doc().layers, hasLength(2));
      expect(doc().layers[1].id, removedId);
      expect(doc().layers[1].strokes, hasLength(1));
      expect(doc().activeLayerIndex, 1);
    });

    test('removing the only layer records nothing', () {
      actions().remove(0);

      expect(doc().layers, hasLength(1));
      expect(undoCount(), 0);
    });

    test('remove with a bad index records nothing', () {
      actions().add('Two');
      final before = undoCount();

      actions().remove(7);
      actions().remove(-1);

      expect(undoCount(), before);
      expect(doc().layers, hasLength(2));
    });

    test('reorder is one undo step and follows the active layer', () {
      actions().add('Two');
      actions().add('Three');
      final before = undoCount();
      final orderBefore = names();

      actions().reorder(2, 0);
      expect(undoCount(), before + 1);
      expect(names(), [orderBefore[2], orderBefore[0], orderBefore[1]]);
      expect(doc().activeLayerIndex, 0);

      undo();
      expect(names(), orderBefore);
      expect(doc().activeLayerIndex, 2);
    });

    test('reorder no-ops record nothing', () {
      actions().add('Two');
      final before = undoCount();

      actions().reorder(0, 0);
      actions().reorder(0, 5);
      actions().reorder(-1, 0);

      expect(undoCount(), before);
    });

    test('duplicate is active at index + 1; undo removes it', () {
      actions().add('Two');
      final before = undoCount();
      final sourceId = doc().layers[0].id;
      final sourceName = doc().layers[0].name;

      actions().duplicate(0);
      expect(undoCount(), before + 1);
      expect(doc().layers, hasLength(3));
      expect(doc().activeLayerIndex, 1);
      expect(doc().layers[1].id, isNot(sourceId));
      expect(doc().layers[1].name, '$sourceName (2)');

      undo();
      expect(doc().layers, hasLength(2));
      expect(doc().layers[0].id, sourceId);
      expect(doc().activeLayerIndex, 1);
    });

    test('duplicate increments an existing copy number', () {
      container.read(documentProvider.notifier).renameLayer(0, 'Ink (2)');
      actions().duplicate(0);

      expect(doc().layers[1].name, 'Ink (3)');
    });
  });
}
