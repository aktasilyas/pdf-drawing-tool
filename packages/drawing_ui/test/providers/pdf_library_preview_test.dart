import 'dart:typed_data';

import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int> widths;
  late ProviderContainer container;

  setUp(() {
    widths = [];
    container = ProviderContainer(overrides: [
      pdfWidthRasterizerProvider.overrideWithValue((path, page, width) async {
        widths.add(width);
        return Uint8List.fromList([width % 256]);
      }),
    ]);
  });
  tearDown(() => container.dispose());

  test('renders at the requested width and caches the result', () async {
    await renderLibraryPreview(container, 'a.pdf|1', width: 720);
    await renderLibraryPreview(container, 'a.pdf|1', width: 720);
    expect(widths, [720]);
  });

  test('caps the width', () async {
    await renderLibraryPreview(container, 'a.pdf|1', width: 5000);
    expect(widths, [maxLibraryPreviewWidth]);
  });

  test('does not touch the sidebar thumbnail cache', () async {
    await renderLibraryPreview(container, 'a.pdf|1', width: 480);
    expect(container.read(pdfThumbnailCacheProvider), isEmpty);
  });

  test('cache is bounded', () async {
    for (var i = 1; i <= maxLibraryPreviews + 5; i++) {
      await renderLibraryPreview(container, 'a.pdf|$i', width: 480);
    }
    expect(container.read(pdfLibraryPreviewCacheProvider),
        hasLength(maxLibraryPreviews));
  });

  test('a full cache never evicts a preview a mounted tile pins', () async {
    final pins = container.read(libraryPreviewPinsProvider);
    await renderLibraryPreview(container, 'a.pdf|1', width: 480);
    final pinned = libraryPreviewKey('a.pdf|1', 480);
    pins.pin(pinned);
    for (var i = 2; i <= maxLibraryPreviews + 5; i++) {
      await renderLibraryPreview(container, 'a.pdf|$i', width: 480);
    }
    final cache = container.read(pdfLibraryPreviewCacheProvider);
    expect(cache, contains(pinned));
    expect(cache, hasLength(maxLibraryPreviews));

    pins.unpin(pinned);
    await renderLibraryPreview(container, 'b.pdf|1', width: 480);
    expect(container.read(pdfLibraryPreviewCacheProvider),
        isNot(contains(pinned)));
  });

  test('the cache grows past the cap only while every entry is pinned',
      () async {
    final pins = container.read(libraryPreviewPinsProvider);
    for (var i = 1; i <= maxLibraryPreviews + 1; i++) {
      pins.pin(libraryPreviewKey('a.pdf|$i', 480));
      await renderLibraryPreview(container, 'a.pdf|$i', width: 480);
    }
    expect(container.read(pdfLibraryPreviewCacheProvider),
        hasLength(maxLibraryPreviews + 1));
  });

  test('a key pinned twice stays pinned until both unpin', () {
    final pins = LibraryPreviewPins()
      ..pin('k')
      ..pin('k')
      ..unpin('k');
    expect(pins.contains('k'), isTrue);
    pins.unpin('k');
    expect(pins.contains('k'), isFalse);
    pins.unpin('k'); // extra unpin is harmless
    expect(pins.contains('k'), isFalse);
  });

  test('clearLibraryPreviewsProvider empties the library preview cache',
      () async {
    await renderLibraryPreview(container, 'a.pdf|1', width: 480);
    container.read(clearLibraryPreviewsProvider)();
    expect(container.read(pdfLibraryPreviewCacheProvider), isEmpty);
  });

  test('the widest preview is the widest tile at the highest DPR', () {
    expect(
      maxLibraryPreviewWidth,
      (libraryPreviewTileWidth * libraryPreviewMaxDpr).ceil(),
    );
  });

  test('preview width follows the DPR within 1..max', () {
    expect(libraryPreviewWidth(0.5), libraryPreviewTileWidth.ceil());
    expect(libraryPreviewWidth(2), (libraryPreviewTileWidth * 2).ceil());
    expect(libraryPreviewWidth(4), maxLibraryPreviewWidth);
  });

  test('failure returns null and is not cached', () async {
    final c = ProviderContainer(overrides: [
      pdfWidthRasterizerProvider.overrideWithValue((_, __, ___) async => null),
    ]);
    addTearDown(c.dispose);
    expect(await renderLibraryPreview(c, 'a.pdf|1', width: 480), isNull);
    expect(c.read(pdfLibraryPreviewCacheProvider), isEmpty);
  });
}
