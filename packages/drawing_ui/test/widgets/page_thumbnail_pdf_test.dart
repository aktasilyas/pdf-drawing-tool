// Page-sidebar thumbnails of PDF pages come from the page rasterizer, so the
// annotations show on top of the PDF page, and the sidebar no longer renders
// the raw PDF page per cell (#496).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';
import 'package:drawing_ui/src/widgets/page_thumbnail.dart';
import 'package:drawing_ui/src/widgets/page_thumbnail_parts.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _pdfPath = '/nonexistent/elyanotes_thumb.pdf';

/// A PDF page whose file is missing, with a thick black diagonal stroke.
Page _annotatedPdfPage() => Page.create(
      index: 2,
      size: const PageSize(width: 200, height: 300),
      background: PageBackground.pdfLazy(pageIndex: 3, pdfFilePath: _pdfPath),
    ).addStroke(Stroke.create(
      points: [
        DrawingPoint(x: 20, y: 20),
        DrawingPoint(x: 100, y: 150),
        DrawingPoint(x: 180, y: 280),
      ],
      style: StrokeStyle.pen(thickness: 24),
    ));

/// Number of dark pixels in a PNG.
Future<int> _darkPixels(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData();
  image.dispose();
  var dark = 0;
  for (var i = 0; i + 3 < data!.lengthInBytes; i += 4) {
    final r = data.getUint8(i);
    final g = data.getUint8(i + 1);
    final b = data.getUint8(i + 2);
    if (r < 80 && g < 80 && b < 80) dark++;
  }
  return dark;
}

void main() {
  testWidgets(
      'a PDF page thumbnail is the rasterizer render with its ink, '
      'not the raw PDF page', (tester) async {
    final page = _annotatedPdfPage();
    final cache = ThumbnailCache(maxSize: 10);
    // A raw PDF page thumbnail is already cached: the old special case
    // showed it at once and discarded the annotated render.
    final rawPdfKey = '$_pdfPath|3';
    final rawPdf = Uint8List.fromList([1, 2, 3, 4]);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pdfThumbnailCacheProvider.notifier).state = {
      rawPdfKey: rawPdf,
    };

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: PageThumbnail(page: page, cache: cache),
        ),
      ),
    ));

    // Loading: the PDF placeholder, never the raw PDF page.
    expect(find.byType(PdfThumbnailPlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();

    final generated = cache.get(ThumbnailGenerator.getCacheKey(page));
    expect(generated, isNotNull, reason: 'ThumbnailGenerator rendered it');
    final shown = tester.widget<Image>(find.byType(Image)).image;
    expect(shown, isA<MemoryImage>());
    expect((shown as MemoryImage).bytes, same(generated));
    expect(find.byType(PdfThumbnailPlaceholder), findsNothing);

    // The stroke is in the render, on the placeholder paper of the missing
    // PDF, instead of a blank cell.
    final dark = await tester.runAsync(() => _darkPixels(generated!));
    expect(dark, greaterThan(20));

    // The sidebar did not go through renderThumbnail.
    expect(container.read(pdfThumbnailCacheProvider).keys, [rawPdfKey]);
  });

  testWidgets('editing a PDF page regenerates its thumbnail', (tester) async {
    var page = _annotatedPdfPage();
    final cache = ThumbnailCache(maxSize: 10);

    Future<void> pumpPage() => tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: PageThumbnail(page: page, cache: cache)),
          ),
        ));

    await pumpPage();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    expect(cache.get(ThumbnailGenerator.getCacheKey(page)), isNotNull);

    page = page.copyWith(updatedAt: page.updatedAt.add(const Duration(seconds: 1)));
    await pumpPage();
    await tester.pump();
    expect(find.byType(PdfThumbnailPlaceholder), findsOneWidget);

    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    expect(cache.get(ThumbnailGenerator.getCacheKey(page)), isNotNull);
    expect(find.byType(Image), findsOneWidget);
  });
}
