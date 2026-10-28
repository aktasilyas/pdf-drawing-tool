import 'dart:io';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/data/datasources/image_background_loader.dart';

void main() {
  late Directory dir;
  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  setUp(() => dir = Directory.systemTemp.createTempSync('elya_img_load_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Page pageWith(String id, PageBackground background) => Page(
        id: id,
        index: 0,
        size: PageSize.a4Portrait,
        background: background,
        layers: [Layer.empty('L')],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

  DrawingDocument docOf(List<Page> pages) => DrawingDocument.multiPage(
        id: 'd',
        title: 'T',
        pages: pages,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

  group('loadImageBackground', () {
    test('fills pdfData from a root-relative path', () async {
      Directory('${dir.path}/elyanotes_images').createSync();
      File('${dir.path}/elyanotes_images/a.png').writeAsBytesSync(bytes);
      final bg = PageBackground(
        type: BackgroundType.pdf,
        pdfPageIndex: 1,
        imageFilePath: 'elyanotes_images/a.png',
      );

      final loaded = await loadImageBackground(bg, PdfPathResolver(dir.path));

      expect(loaded.pdfData, bytes);
      expect(loaded.imageFilePath, 'elyanotes_images/a.png');
    });

    test('a missing file leaves pdfData null and does not throw', () async {
      final bg = PageBackground(
        type: BackgroundType.pdf,
        pdfPageIndex: 1,
        imageFilePath: 'elyanotes_images/gone.png',
      );

      final loaded = await loadImageBackground(bg, PdfPathResolver(dir.path));

      expect(loaded.pdfData, isNull);
      expect(loaded.imageFilePath, 'elyanotes_images/gone.png');
    });

    test('backgrounds without an image file are returned as is', () async {
      final pdf = PageBackground.pdfLazy(pageIndex: 1, pdfFilePath: 'x.pdf');
      expect(await loadImageBackground(pdf, PdfPathResolver(dir.path)),
          same(pdf));
      expect(
        await loadImageBackground(
            PageBackground.blank, PdfPathResolver(dir.path)),
        same(PageBackground.blank),
      );
    });
  });

  group('loadImageBackgrounds', () {
    test('fills image pages and leaves PDF pages untouched', () async {
      final file = File('${dir.path}/img.png')..writeAsBytesSync(bytes);
      final pdfBg = PageBackground.pdfLazy(pageIndex: 3, pdfFilePath: 'a.pdf');
      final doc = docOf([
        pageWith(
          'img',
          PageBackground(
            type: BackgroundType.pdf,
            pdfPageIndex: 1,
            imageFilePath: file.path,
          ),
        ),
        pageWith('pdf', pdfBg),
      ]);

      final loaded =
          await loadImageBackgrounds(doc, PdfPathResolver.passthrough);

      expect(loaded.pages[0].background.pdfData, bytes);
      expect(loaded.pages[0].updatedAt, doc.pages[0].updatedAt);
      expect(loaded.pages[1].background, same(pdfBg));
      expect(loaded.pages[1].background.pdfData, isNull);
    });

    test('a missing file does not throw and keeps the page', () async {
      final doc = docOf([
        pageWith(
          'img',
          PageBackground(
            type: BackgroundType.pdf,
            pdfPageIndex: 1,
            imageFilePath: '${dir.path}/missing.png',
          ),
        ),
      ]);

      final loaded =
          await loadImageBackgrounds(doc, PdfPathResolver.passthrough);

      expect(loaded.pages.single.background.pdfData, isNull);
      expect(loaded.pages.single.id, 'img');
    });

    test('returns the same document when nothing needs loading', () async {
      final doc = docOf([pageWith('p', PageBackground.blank)]);
      expect(
        await loadImageBackgrounds(doc, PdfPathResolver.passthrough),
        same(doc),
      );
    });
  });
}
