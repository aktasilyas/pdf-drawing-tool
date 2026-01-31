import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';

void main() {
  // ===========================================================================
  // CanvasTransform Tests
  // ===========================================================================

  group('CanvasTransform', () {
    test('default values are zoom 1.0 and offset zero', () {
      const transform = CanvasTransform();
      expect(transform.zoom, 1.0);
      expect(transform.offset, Offset.zero);
    });

    test('copyWith creates new instance with updated values', () {
      const original = CanvasTransform(zoom: 1.0, offset: Offset.zero);
      final updated = original.copyWith(zoom: 2.0, offset: const Offset(100, 50));

      expect(updated.zoom, 2.0);
      expect(updated.offset, const Offset(100, 50));
      expect(original.zoom, 1.0); // Original unchanged
    });

    test('copyWith preserves unchanged values', () {
      const original = CanvasTransform(zoom: 1.5, offset: Offset(10, 20));
      final updated = original.copyWith(zoom: 2.0);

      expect(updated.zoom, 2.0);
      expect(updated.offset, const Offset(10, 20)); // Preserved
    });

    test('screenToCanvas converts coordinates correctly', () {
      const transform = CanvasTransform(zoom: 2.0, offset: Offset(100, 50));
      final canvasPoint = transform.screenToCanvas(const Offset(200, 150));

      // (200 - 100) / 2 = 50, (150 - 50) / 2 = 50
      expect(canvasPoint.dx, 50.0);
      expect(canvasPoint.dy, 50.0);
    });

    test('canvasToScreen converts coordinates correctly', () {
      const transform = CanvasTransform(zoom: 2.0, offset: Offset(100, 50));
      final screenPoint = transform.canvasToScreen(const Offset(50, 50));

      // 50 * 2 + 100 = 200, 50 * 2 + 50 = 150
      expect(screenPoint.dx, 200.0);
      expect(screenPoint.dy, 150.0);
    });

    test('screenToCanvas and canvasToScreen are inverse operations', () {
      const transform = CanvasTransform(zoom: 1.5, offset: Offset(30, 40));
      const originalScreen = Offset(100, 100);

      final canvas = transform.screenToCanvas(originalScreen);
      final backToScreen = transform.canvasToScreen(canvas);

      expect(backToScreen.dx, closeTo(originalScreen.dx, 0.001));
      expect(backToScreen.dy, closeTo(originalScreen.dy, 0.001));
    });

    test('matrix returns correct transformation matrix', () {
      const transform = CanvasTransform(zoom: 2.0, offset: Offset(10, 20));
      final matrix = transform.matrix;

      // The matrix should translate then scale
      expect(matrix.getTranslation().x, 10.0);
      expect(matrix.getTranslation().y, 20.0);
    });

    test('equality operator works correctly', () {
      const t1 = CanvasTransform(zoom: 1.5, offset: Offset(10, 20));
      const t2 = CanvasTransform(zoom: 1.5, offset: Offset(10, 20));
      const t3 = CanvasTransform(zoom: 2.0, offset: Offset(10, 20));

      expect(t1, equals(t2));
      expect(t1, isNot(equals(t3)));
    });
  });

  // ===========================================================================
  // CanvasTransformNotifier Tests
  // ===========================================================================

  group('CanvasTransformNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is zoom 1.0 and offset zero', () {
      final transform = container.read(canvasTransformProvider);
      expect(transform.zoom, 1.0);
      expect(transform.offset, Offset.zero);
    });

    test('setZoom updates zoom level', () {
      container.read(canvasTransformProvider.notifier).setZoom(2.0);
      expect(container.read(canvasTransformProvider).zoom, 2.0);
    });

    test('setZoom clamps to minimum', () {
      container.read(canvasTransformProvider.notifier).setZoom(0.1);
      expect(container.read(canvasTransformProvider).zoom, CanvasTransform.minZoom);
    });

    test('setZoom clamps to maximum', () {
      container.read(canvasTransformProvider.notifier).setZoom(10.0);
      expect(container.read(canvasTransformProvider).zoom, CanvasTransform.maxZoom);
    });

    test('setOffset updates offset', () {
      container.read(canvasTransformProvider.notifier).setOffset(const Offset(100, 50));
      expect(container.read(canvasTransformProvider).offset, const Offset(100, 50));
    });

    test('applyPanDelta adds to existing offset', () {
      container.read(canvasTransformProvider.notifier).setOffset(const Offset(50, 50));
      container.read(canvasTransformProvider.notifier).applyPanDelta(const Offset(25, 25));

      expect(container.read(canvasTransformProvider).offset, const Offset(75, 75));
    });

    test('applyZoomDelta multiplies zoom', () {
      container.read(canvasTransformProvider.notifier).setZoom(1.0);
      container.read(canvasTransformProvider.notifier).applyZoomDelta(1.5, Offset.zero);

      expect(container.read(canvasTransformProvider).zoom, 1.5);
    });

    test('applyZoomDelta clamps result', () {
      container.read(canvasTransformProvider.notifier).setZoom(4.0);
      container.read(canvasTransformProvider.notifier).applyZoomDelta(2.0, Offset.zero);

      expect(container.read(canvasTransformProvider).zoom, CanvasTransform.maxZoom);
    });

    test('reset returns to default state', () {
      container.read(canvasTransformProvider.notifier).setZoom(2.0);
      container.read(canvasTransformProvider.notifier).setOffset(const Offset(100, 100));
      container.read(canvasTransformProvider.notifier).reset();

      final transform = container.read(canvasTransformProvider);
      expect(transform.zoom, 1.0);
      expect(transform.offset, Offset.zero);
    });

    test('fitToScreen returns to default state', () {
      container.read(canvasTransformProvider.notifier).setZoom(3.0);
      container.read(canvasTransformProvider.notifier).setOffset(const Offset(200, 200));
      container.read(canvasTransformProvider.notifier).fitToScreen();

      final transform = container.read(canvasTransformProvider);
      expect(transform.zoom, 1.0);
      expect(transform.offset, Offset.zero);
    });

    test('zoomIn increases zoom by 25%', () {
      container.read(canvasTransformProvider.notifier).setZoom(1.0);
      container.read(canvasTransformProvider.notifier).zoomIn();

      expect(container.read(canvasTransformProvider).zoom, 1.25);
    });

    test('zoomOut decreases zoom by 20%', () {
      container.read(canvasTransformProvider.notifier).setZoom(1.0);
      container.read(canvasTransformProvider.notifier).zoomOut();

      expect(container.read(canvasTransformProvider).zoom, 0.8);
    });
  });

  // ===========================================================================
  // Convenience Providers Tests
  // ===========================================================================

  group('Convenience Providers', () {
    test('zoomLevelProvider returns current zoom', () {
      final container = ProviderContainer();

      expect(container.read(zoomLevelProvider), 1.0);

      container.read(canvasTransformProvider.notifier).setZoom(2.5);
      expect(container.read(zoomLevelProvider), 2.5);

      container.dispose();
    });

    test('zoomPercentageProvider returns formatted string', () {
      final container = ProviderContainer();

      expect(container.read(zoomPercentageProvider), '100%');

      container.read(canvasTransformProvider.notifier).setZoom(1.5);
      expect(container.read(zoomPercentageProvider), '150%');

      container.read(canvasTransformProvider.notifier).setZoom(0.5);
      expect(container.read(zoomPercentageProvider), '50%');

      container.dispose();
    });

    test('isDefaultZoomProvider returns true at 100%', () {
      final container = ProviderContainer();

      expect(container.read(isDefaultZoomProvider), true);

      container.read(canvasTransformProvider.notifier).setZoom(1.5);
      expect(container.read(isDefaultZoomProvider), false);

      container.read(canvasTransformProvider.notifier).setZoom(1.0);
      expect(container.read(isDefaultZoomProvider), true);

      container.dispose();
    });

    test('canZoomInProvider returns false at max zoom', () {
      final container = ProviderContainer();

      expect(container.read(canZoomInProvider), true);

      container.read(canvasTransformProvider.notifier).setZoom(CanvasTransform.maxZoom);
      expect(container.read(canZoomInProvider), false);

      container.dispose();
    });

    test('canZoomOutProvider returns false at min zoom', () {
      final container = ProviderContainer();

      expect(container.read(canZoomOutProvider), true);

      container.read(canvasTransformProvider.notifier).setZoom(CanvasTransform.minZoom);
      expect(container.read(canZoomOutProvider), false);

      container.dispose();
    });
  });
}
