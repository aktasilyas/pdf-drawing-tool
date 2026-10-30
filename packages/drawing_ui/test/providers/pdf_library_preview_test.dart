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

  test('failure returns null and is not cached', () async {
    final c = ProviderContainer(overrides: [
      pdfWidthRasterizerProvider.overrideWithValue((_, __, ___) async => null),
    ]);
    addTearDown(c.dispose);
    expect(await renderLibraryPreview(c, 'a.pdf|1', width: 480), isNull);
    expect(c.read(pdfLibraryPreviewCacheProvider), isEmpty);
  });
}
