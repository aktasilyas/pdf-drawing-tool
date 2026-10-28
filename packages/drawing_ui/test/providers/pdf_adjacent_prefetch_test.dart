import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';

// Paging through a PDF prefetches the neighbours of the visible page on the
// provider's own ref, after a delay that a newer page change cancels (#362).

/// Fake rasteriser: records the requested 1-based page numbers.
class _FakeRasterizer {
  final pages = <int>[];

  Future<Uint8List?> call(String path, int page, double quality) async {
    pages.add(page);
    return Uint8List.fromList([page]);
  }
}

ProviderContainer _container(_FakeRasterizer raster) {
  final container = ProviderContainer(overrides: [
    pdfPageRasterizerProvider.overrideWithValue(raster.call),
  ]);
  container.read(currentPdfFilePathProvider.notifier).state = 'doc.pdf';
  container.read(totalPdfPagesProvider.notifier).state = 20;
  return container;
}

/// Stands in for the canvas: turns to [page] through the same handler.
class _Pager extends ConsumerWidget {
  const _Pager({required this.page});

  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => prefetchOnPageChange(ref, page),
      child: const SizedBox(width: 48, height: 48),
    );
  }
}

void main() {
  testWidgets('disposing the canvas inside the delay throws nothing',
      (tester) async {
    final raster = _FakeRasterizer();
    final container = _container(raster);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Pager(page: 5)),
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pump(const Duration(milliseconds: 100));

    // The canvas goes away before the 500 ms prefetch delay ends.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(raster.pages.toSet(), {5, 6, 4, 7, 3});
  });

  testWidgets('a disposed container cancels the pending prefetch',
      (tester) async {
    final raster = _FakeRasterizer();
    final container = _container(raster);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Pager(page: 5)),
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pump(const Duration(milliseconds: 100));
    final prefetcher = container.read(pdfAdjacentPrefetchProvider);
    expect(prefetcher.isPending, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(prefetcher.isPending, isFalse);
    expect(raster.pages, [5]);
  });

  test('a rapid page change prefetches only around the last page', () async {
    final raster = _FakeRasterizer();
    final container = _container(raster);
    addTearDown(container.dispose);
    final prefetcher = container.read(pdfAdjacentPrefetchProvider);

    for (final page in [2, 9, 15]) {
      prefetcher.schedule(pdfFilePath: 'doc.pdf', page: page, totalPages: 20);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(raster.pages, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(raster.pages.toSet(), {16, 14, 17, 13});
  });

  test('prefetch stays inside the document and skips cached pages', () async {
    final raster = _FakeRasterizer();
    final container = _container(raster);
    addTearDown(container.dispose);
    addToPdfPageCacheForTest(container, 'doc.pdf|2');

    container
        .read(pdfAdjacentPrefetchProvider)
        .schedule(pdfFilePath: 'doc.pdf', page: 1, totalPages: 20);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(raster.pages.toSet(), {3});
  });
}

/// Puts a rendered page into the page cache, as a finished render would.
void addToPdfPageCacheForTest(ProviderContainer container, String key) {
  container.read(pdfPageCacheProvider.notifier).update(
        (cache) => {...cache, key: Uint8List.fromList([0])},
      );
}
