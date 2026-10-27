import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_background_rasterizer.dart';
import 'package:flutter_test/flutter_test.dart';

// Exported template and cover backgrounds must match the canvas (#287): the
// rasterizer goes through the canvas painters, not a second grid renderer.

const _w = 595.0; // A4 portrait in PDF points
const _h = 842.0;
const _dpi = 36; // half scale keeps the test fast; patterns stay visible

PageBackground _template(
  TemplatePattern pattern, {
  Map<String, dynamic>? extraData,
}) =>
    PageBackground(
      type: BackgroundType.template,
      templatePattern: pattern,
      templateSpacingMm: pattern.defaultSpacingMm,
      templateLineWidth: pattern.defaultLineWidth,
      lineColor: 0xFF9E9E9E,
      templateExtraData: extraData,
    );

Future<Uint8List> _pixels(PageBackground bg) async {
  final raw = await PdfBackgroundRasterizer().render(bg, _w, _h, _dpi);
  expect(raw, isNotNull);
  return raw!.bytes;
}

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every template pattern rasterizes its own paper', () async {
    final blank = await _pixels(_template(TemplatePattern.blank));
    // The old exporter drew this grid for every template.
    final grid = await _pixels(_template(TemplatePattern.mediumGrid));
    for (final pattern in TemplatePattern.values) {
      if (pattern == TemplatePattern.blank) continue;
      final pixels = await _pixels(_template(pattern));
      expect(_same(pixels, blank), isFalse, reason: '$pattern is empty');
      if (!pattern.hasGrid && !pattern.hasDots) {
        expect(_same(pixels, grid), isFalse,
            reason: '$pattern exports the plain grid');
      }
    }
  });

  test('templateExtraData is respected (engineer pad margin)', () async {
    final plain = await _pixels(_template(TemplatePattern.smallGrid));
    final margin = await _pixels(_template(
      TemplatePattern.smallGrid,
      extraData: const {'showMarginLeft': true, 'marginMm': 25},
    ));
    expect(_same(plain, margin), isFalse);
  });

  test('covers render through the cover painter, not a flat color', () async {
    // A gradient cover paints its own colors over the base color (a pattern
    // cover's white-on-dark dots would vanish on the white base used here).
    const gradient = CoverStyle.gradient;
    final cover = CoverRegistry.all.firstWhere((c) => c.style == gradient);
    final bg = PageBackground(
      type: BackgroundType.cover,
      coverId: cover.id,
      color: 0xFFFFFFFF,
    );
    final flat = PageBackground(type: BackgroundType.blank, color: bg.color);
    expect(_same(await _pixels(bg), await _pixels(flat)), isFalse);
  });

  test('raster is opaque and sized from the DPI', () async {
    final raw = await PdfBackgroundRasterizer().render(
      _template(TemplatePattern.cornell).copyWith(color: 0x00FFFFFF),
      _w,
      _h,
      _dpi,
    );
    expect(raw!.width, (_w * _dpi / 72).round());
    expect(raw.height, (_h * _dpi / 72).round());
    for (var i = 3; i < raw.bytes.length; i += 4) {
      if (raw.bytes[i] != 255) fail('pixel ${i ~/ 4} is not opaque');
    }
  });

  test('scale is capped by maxDpi and maxSidePx', () {
    expect(
      PdfBackgroundRasterizer.scaleFor(_w, _h, 600),
      PdfBackgroundRasterizer.maxDpi / 72,
    );
    expect(PdfBackgroundRasterizer.scaleFor(_w, _h, 150), 150 / 72);
    expect(
      PdfBackgroundRasterizer.scaleFor(10000, 500, 300),
      PdfBackgroundRasterizer.maxSidePx / 10000,
    );
  });
}
