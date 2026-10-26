import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';

/// Waits past the 150 ms zoom debounce and lets pending futures run.
Future<void> _afterDebounce() =>
    Future<void>.delayed(const Duration(milliseconds: 250));

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

/// Fake rasteriser: records calls, answers from [results] (bytes by default).
class _FakeRasterizer {
  final calls = <String>[];
  final results = <Uint8List?>[];

  Future<Uint8List?> call(String path, int page, double quality) async {
    calls.add('$path|$page@${quality}x');
    if (results.isNotEmpty) return results.removeAt(0);
    return Uint8List.fromList([page, quality.round()]);
  }
}

ProviderContainer _container(_FakeRasterizer raster) {
  final container = ProviderContainer(overrides: [
    pdfPageRasterizerProvider.overrideWithValue(raster.call),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('staleQualityKeys', () {
    test('matches only the exact page prefix', () {
      final keys = [
        'doc.pdf|1',
        'doc.pdf|1@1.5x',
        'doc.pdf|1@2.5x',
        'doc.pdf|10@2.0x',
        'doc.pdf|19@2.5x',
      ];
      expect(
        staleQualityKeys(keys, 'doc.pdf|1', 'doc.pdf|1@2.5x'),
        ['doc.pdf|1@1.5x'],
      );
    });
  });

  group('zoom HQ render', () {
    test('saturated limit, zoom, free slots, zoom again -> HQ render happens',
        () async {
      final raster = _FakeRasterizer();
      final container = _container(raster);
      final slots = container.read(pdfRenderSlotsProvider);
      final notifier = container.read(zoomBasedRenderProvider.notifier);

      // Saturate the concurrency limit.
      expect(await slots.acquire('other.pdf|1'), isTrue);
      expect(await slots.acquire('other.pdf|2'), isTrue);

      notifier.onZoomChanged(2.5, 'doc.pdf|1');
      await _afterDebounce();
      expect(raster.calls, isEmpty);

      // Free the slots: the queued HQ render runs without another zoom.
      slots.release('other.pdf|1');
      slots.release('other.pdf|2');
      await _settle();
      expect(raster.calls, ['doc.pdf|1@2.5x']);
      expect(container.read(pdfPageCacheProvider), contains('doc.pdf|1@2.5x'));
      expect(slots.isBusy('doc.pdf|1@2.5x'), isFalse);
      expect(slots.activeCount, 0);

      // Zoom again to another quality: renders, and the old quality of the
      // same page is evicted.
      notifier.onZoomChanged(1.8, 'doc.pdf|1');
      await _afterDebounce();
      expect(raster.calls, ['doc.pdf|1@2.5x', 'doc.pdf|1@2.0x']);
      final cache = container.read(pdfPageCacheProvider);
      expect(cache, contains('doc.pdf|1@2.0x'));
      expect(cache, isNot(contains('doc.pdf|1@2.5x')));
    });

    test('a failed HQ render does not block the next zoom', () async {
      final raster = _FakeRasterizer()..results.add(null);
      final container = _container(raster);
      final notifier = container.read(zoomBasedRenderProvider.notifier);

      notifier.onZoomChanged(2.5, 'doc.pdf|1');
      await _afterDebounce();
      expect(container.read(pdfPageCacheProvider), isEmpty);

      notifier.onZoomChanged(2.6, 'doc.pdf|1');
      await _afterDebounce();
      expect(raster.calls, ['doc.pdf|1@2.5x', 'doc.pdf|1@2.5x']);
      expect(container.read(pdfPageCacheProvider), contains('doc.pdf|1@2.5x'));
    });

    test('HQ cleanup keeps other pages that share the prefix', () async {
      final raster = _FakeRasterizer();
      final container = _container(raster);
      container.read(pdfPageCacheProvider.notifier).state = {
        'doc.pdf|10@2.0x': Uint8List(1),
        'doc.pdf|1@2.0x': Uint8List(1),
      };

      final notifier = container.read(zoomBasedRenderProvider.notifier);
      notifier.onZoomChanged(2.5, 'doc.pdf|1');
      await _afterDebounce();

      final cache = container.read(pdfPageCacheProvider);
      expect(cache.keys, containsAll(['doc.pdf|10@2.0x', 'doc.pdf|1@2.5x']));
      expect(cache, isNot(contains('doc.pdf|1@2.0x')));
    });
  });

  group('pdfPageRenderProvider', () {
    test('a null result is not cached; the next request renders again',
        () async {
      final raster = _FakeRasterizer()..results.add(null);
      final container = _container(raster);

      final first =
          await container.read(pdfPageRenderProvider('doc.pdf|3').future);
      expect(first, isNull);
      await _settle();

      final second =
          await container.read(pdfPageRenderProvider('doc.pdf|3').future);
      expect(second, isNotNull);
      expect(raster.calls, ['doc.pdf|3@1.5x', 'doc.pdf|3@1.5x']);
    });

    test('a successful render stays cached', () async {
      final raster = _FakeRasterizer();
      final container = _container(raster);

      await container.read(pdfPageRenderProvider('doc.pdf|3').future);
      await _settle();
      final again =
          await container.read(pdfPageRenderProvider('doc.pdf|3').future);
      expect(again, isNotNull);
      expect(raster.calls, ['doc.pdf|3@1.5x']);
    });

    test('fast scrolling past a saturated limit leaves no placeholders',
        () async {
      final raster = _FakeRasterizer();
      final container = _container(raster);
      final slots = container.read(pdfRenderSlotsProvider);

      // Saturate, then request many pages (like a fast scroll).
      await slots.acquire('busy|1');
      await slots.acquire('busy|2');
      final pages = [for (var p = 1; p <= 12; p++) 'doc.pdf|$p'];
      final futures = [
        for (final key in pages)
          container.read(pdfPageRenderProvider(key).future),
      ];

      // Nothing times out: every request waits for its turn.
      slots.release('busy|1');
      slots.release('busy|2');
      final results = await Future.wait(futures);

      expect(results, everyElement(isNotNull));
      expect(raster.calls.length, pages.length);
      expect(slots.activeCount, 0);
    });
  });
}
