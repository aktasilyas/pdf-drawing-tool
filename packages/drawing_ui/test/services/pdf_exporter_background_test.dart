import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

// Template and cover backgrounds are exported with the canvas painters as
// one shared image per distinct background (#287).

Page _page(int i, PageBackground bg) => Page.create(
      index: i,
      size: PageSize.a4Portrait,
    ).copyWith(background: bg);

final _cornell = PageBackground(
  type: BackgroundType.template,
  templatePattern: TemplatePattern.cornell,
  templateSpacingMm: TemplatePattern.cornell.defaultSpacingMm,
  templateLineWidth: TemplatePattern.cornell.defaultLineWidth,
  lineColor: 0xFF9E9E9E,
);

/// Image XObject dictionaries in the saved PDF.
List<String> _images(List<int> pdf) =>
    RegExp(r'<<[^>]*/Subtype\s*/Image[^>]*>>')
        .allMatches(latin1.decode(pdf))
        .map((m) => m.group(0)!)
        .toList();

const _lowDpi = PDFExportOptions(quality: PDFExportQuality.low);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('20 identical template pages embed one background image', () async {
    final result = await PDFExporter().exportPages(
      pages: [for (var i = 0; i < 20; i++) _page(i, _cornell)],
      options: _lowDpi,
    );
    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    final images = _images(result.pdfBytes);
    expect(images, hasLength(1));
    // Opaque paper: no soft mask, Flate-compressed.
    expect(images.single, isNot(contains('/SMask')));
    expect(images.single, contains('/FlateDecode'));
  });

  test('different templates embed one image each', () async {
    const music = PageBackground(
      type: BackgroundType.template,
      templatePattern: TemplatePattern.music,
    );
    final result = await PDFExporter().exportPages(
      pages: [
        _page(0, _cornell),
        _page(1, music),
        _page(2, _cornell),
        _page(3, music),
      ],
      options: _lowDpi,
    );
    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(_images(result.pdfBytes), hasLength(2));
  });

  test('includeBackground: false exports no background', () async {
    final result = await PDFExporter().exportPages(
      pages: [_page(0, _cornell)],
      options: const PDFExportOptions(
        quality: PDFExportQuality.low,
        includeBackground: false,
      ),
    );
    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(_images(result.pdfBytes), isEmpty);
  });

  test('legacy grid backgrounds stay vector', () async {
    final result = await PDFExporter().exportPages(
      pages: [
        _page(0, const PageBackground(type: BackgroundType.grid)),
        _page(1, const PageBackground(type: BackgroundType.lined)),
      ],
      options: _lowDpi,
    );
    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(_images(result.pdfBytes), isEmpty);
  });
}
