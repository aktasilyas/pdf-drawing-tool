import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';

void main() {
  // ===========================================================================
  // DocumentNotifier Tests
  // ===========================================================================

  group('DocumentNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty document', () {
      final document = container.read(documentProvider);
      expect(document.isEmpty, true);
      expect(document.title, 'İsimsiz Not');
    });

    test('addStroke adds stroke to active layer', () {
      final stroke = Stroke.create(style: StrokeStyle.pen());
      container.read(documentProvider.notifier).addStroke(stroke);

      final document = container.read(documentProvider);
      expect(document.strokeCount, 1);
    });

    test('addStroke multiple strokes', () {
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );

      expect(container.read(strokeCountProvider), 3);
    });

    test('removeStroke removes stroke from active layer', () {
      final stroke = Stroke.create(style: StrokeStyle.pen());
      container.read(documentProvider.notifier).addStroke(stroke);
      container.read(documentProvider.notifier).removeStroke(stroke.id);

      final document = container.read(documentProvider);
      expect(document.strokeCount, 0);
    });

    test('removeStroke with invalid id does nothing', () {
      final stroke = Stroke.create(style: StrokeStyle.pen());
      container.read(documentProvider.notifier).addStroke(stroke);
      container.read(documentProvider.notifier).removeStroke('invalid-id');

      expect(container.read(strokeCountProvider), 1);
    });

    test('clearActiveLayer removes all strokes', () {
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      container.read(documentProvider.notifier).clearActiveLayer();

      expect(container.read(strokeCountProvider), 0);
    });

    test('newDocument creates fresh document', () {
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      container.read(documentProvider.notifier).newDocument(title: 'Yeni Not');

      final document = container.read(documentProvider);
      expect(document.isEmpty, true);
      expect(document.title, 'Yeni Not');
    });

    test('newDocument with default title', () {
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      container.read(documentProvider.notifier).newDocument();

      final document = container.read(documentProvider);
      expect(document.title, 'İsimsiz Not');
    });

    test('updateTitle changes document title', () {
      container.read(documentProvider.notifier).updateTitle('Test Başlığı');

      final document = container.read(documentProvider);
      expect(document.title, 'Test Başlığı');
    });

    test('updateDocument replaces entire document', () {
      final newDoc = DrawingDocument.emptyMultiPage('Yeni Doküman');
      container.read(documentProvider.notifier).updateDocument(newDoc);

      final document = container.read(documentProvider);
      expect(document.title, 'Yeni Doküman');
    });

    test('currentDocument returns current state', () {
      final notifier = container.read(documentProvider.notifier);
      notifier.updateTitle('Test');

      expect(notifier.currentDocument.title, 'Test');
    });
  });

  // ===========================================================================
  // Layer Management Tests
  // ===========================================================================

  group('Layer Management', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial document has one layer', () {
      expect(container.read(layerCountProvider), 1);
    });

    test('addLayer increases layer count', () {
      container.read(documentProvider.notifier).addLayer('Katman 2');

      expect(container.read(layerCountProvider), 2);
    });

    test('removeLayer decreases layer count', () {
      container.read(documentProvider.notifier).addLayer('Katman 2');
      container.read(documentProvider.notifier).removeLayer(1);

      expect(container.read(layerCountProvider), 1);
    });

    test('removeLayer does nothing if only one layer', () {
      container.read(documentProvider.notifier).removeLayer(0);

      expect(container.read(layerCountProvider), 1);
    });

    test('setActiveLayer changes active layer', () {
      container.read(documentProvider.notifier).addLayer('Katman 2');
      container.read(documentProvider.notifier).setActiveLayer(1);

      expect(container.read(activeLayerIndexProvider), 1);
    });

    test('setActiveLayer with invalid index does nothing', () {
      container.read(documentProvider.notifier).setActiveLayer(99);

      expect(container.read(activeLayerIndexProvider), 0);
    });

    test('setActiveLayer with negative index does nothing', () {
      container.read(documentProvider.notifier).setActiveLayer(-1);

      expect(container.read(activeLayerIndexProvider), 0);
    });
  });

  // ===========================================================================
  // Derived Providers Tests
  // ===========================================================================

  group('Derived Providers', () {
    test('activeLayerStrokesProvider returns strokes', () {
      final container = ProviderContainer();

      final stroke = Stroke.create(style: StrokeStyle.pen());
      container.read(documentProvider.notifier).addStroke(stroke);

      final strokes = container.read(activeLayerStrokesProvider);
      expect(strokes.length, 1);
      expect(strokes.first.id, stroke.id);

      container.dispose();
    });

    test('activeLayerStrokesProvider is empty initially', () {
      final container = ProviderContainer();

      expect(container.read(activeLayerStrokesProvider), isEmpty);

      container.dispose();
    });

    test('isDocumentEmptyProvider reflects state', () {
      final container = ProviderContainer();

      expect(container.read(isDocumentEmptyProvider), true);

      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );

      expect(container.read(isDocumentEmptyProvider), false);

      container.dispose();
    });

    test('strokeCountProvider updates correctly', () {
      final container = ProviderContainer();

      expect(container.read(strokeCountProvider), 0);

      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      expect(container.read(strokeCountProvider), 1);

      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      expect(container.read(strokeCountProvider), 2);

      container.dispose();
    });

    test('layerCountProvider updates correctly', () {
      final container = ProviderContainer();

      expect(container.read(layerCountProvider), 1);

      container.read(documentProvider.notifier).addLayer('Test');
      expect(container.read(layerCountProvider), 2);

      container.dispose();
    });

    test('activeLayerIndexProvider updates correctly', () {
      final container = ProviderContainer();

      expect(container.read(activeLayerIndexProvider), 0);

      container.read(documentProvider.notifier).addLayer('Test');
      container.read(documentProvider.notifier).setActiveLayer(1);
      expect(container.read(activeLayerIndexProvider), 1);

      container.dispose();
    });
  });

  // ===========================================================================
  // Integration Tests
  // ===========================================================================

  group('Integration', () {
    test('strokes persist after adding to different layers', () {
      final container = ProviderContainer();

      // Add stroke to layer 0
      final stroke1 = Stroke.create(style: StrokeStyle.pen());
      container.read(documentProvider.notifier).addStroke(stroke1);

      // Add new layer and switch to it
      container.read(documentProvider.notifier).addLayer('Layer 2');
      container.read(documentProvider.notifier).setActiveLayer(1);

      // Add stroke to layer 1
      final stroke2 = Stroke.create(style: StrokeStyle.pen());
      container.read(documentProvider.notifier).addStroke(stroke2);

      // Total strokes should be 2
      expect(container.read(strokeCountProvider), 2);

      // Active layer should only have 1 stroke
      expect(container.read(activeLayerStrokesProvider).length, 1);

      // Switch back to layer 0
      container.read(documentProvider.notifier).setActiveLayer(0);
      expect(container.read(activeLayerStrokesProvider).length, 1);

      container.dispose();
    });

    test('clear active layer only clears current layer', () {
      final container = ProviderContainer();

      // Add strokes to layer 0
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );

      // Add new layer and add strokes
      container.read(documentProvider.notifier).addLayer('Layer 2');
      container.read(documentProvider.notifier).setActiveLayer(1);
      container.read(documentProvider.notifier).addStroke(
            Stroke.create(style: StrokeStyle.pen()),
          );

      // Total = 3
      expect(container.read(strokeCountProvider), 3);

      // Clear active layer (layer 1)
      container.read(documentProvider.notifier).clearActiveLayer();

      // Layer 1 should be empty
      expect(container.read(activeLayerStrokesProvider).length, 0);

      // But total should still be 2 (from layer 0)
      expect(container.read(strokeCountProvider), 2);

      container.dispose();
    });
  });
}
