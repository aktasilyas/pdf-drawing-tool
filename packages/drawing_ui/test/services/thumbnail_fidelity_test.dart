import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Thumbnails must look like the canvas page (#256): every template renders
/// its own pattern, and strokes go through the canvas stroke renderer.

Page _templatePage(TemplatePattern pattern) => Page.create(
      index: 0,
      size: PageSize.a4Portrait,
      background: PageBackground(
        type: BackgroundType.template,
        templatePattern: pattern,
        templateSpacingMm: pattern.defaultSpacingMm,
        templateLineWidth: pattern.defaultLineWidth,
        lineColor: 0xFF9E9E9E,
      ),
    );

Future<ByteData> _pixels(Page page) async {
  final png = await ThumbnailGenerator.generate(page, width: 300, height: 424);
  expect(png, isNotNull);
  final codec = await ui.instantiateImageCodec(png!);
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData())!;
  image.dispose();
  return data;
}

bool _samePixels(ByteData a, ByteData b) {
  if (a.lengthInBytes != b.lengthInBytes) return false;
  for (var i = 0; i < a.lengthInBytes; i++) {
    if (a.getUint8(i) != b.getUint8(i)) return false;
  }
  return true;
}

/// Pixels in the box (thumbnail coordinates) that are not near-white.
int _inkedPixels(ByteData data, int width, ui.Rect box) {
  var n = 0;
  for (var y = box.top.toInt(); y < box.bottom.toInt(); y++) {
    for (var x = box.left.toInt(); x < box.right.toInt(); x++) {
      final i = (y * width + x) * 4;
      final dark = data.getUint8(i) < 200 ||
          data.getUint8(i + 1) < 200 ||
          data.getUint8(i + 2) < 200;
      if (dark) n++;
    }
  }
  return n;
}

void testGenerate(String name, Future<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(body);
  });
}

void main() {
  testGenerate('every template pattern renders its own background', () async {
    final blank = await _pixels(_templatePage(TemplatePattern.blank));
    // The old generator drew this grid for every non-basic pattern.
    final grid = await _pixels(_templatePage(TemplatePattern.mediumGrid));
    final seen = <TemplatePattern, ByteData>{};
    for (final pattern in TemplatePattern.values) {
      if (pattern == TemplatePattern.blank) continue;
      final pixels = await _pixels(_templatePage(pattern));
      expect(_samePixels(pixels, blank), isFalse,
          reason: '$pattern renders nothing');
      if (!pattern.hasGrid && !pattern.hasDots) {
        expect(_samePixels(pixels, grid), isFalse,
            reason: '$pattern falls back to the plain grid');
      }
      seen[pattern] = pixels;
    }
    // Structured templates are distinct from each other.
    final structured = [
      for (final p in TemplatePattern.values)
        if (p.isStructured || p == TemplatePattern.cornell) p,
    ];
    for (var i = 0; i < structured.length; i++) {
      for (var j = i + 1; j < structured.length; j++) {
        expect(
          _samePixels(seen[structured[i]]!, seen[structured[j]]!),
          isFalse,
          reason: '${structured[i]} == ${structured[j]}',
        );
      }
    }
  });

  testGenerate('a single-point (dot) stroke appears', () async {
    final page = Page.create(index: 0, size: PageSize.a4Portrait).addStroke(
      Stroke.create(
        points: [DrawingPoint(x: 300, y: 400, pressure: 0.8)],
        style: StrokeStyle.pen(color: 0xFF000000, thickness: 12),
      ),
    );
    final data = await _pixels(page);
    // A4 at 300 px wide: scale ~0.504, the dot sits near (151, 202).
    expect(
      _inkedPixels(data, 300, const ui.Rect.fromLTWH(140, 190, 24, 24)),
      greaterThan(0),
    );
  });

  testGenerate('hidden layers are not drawn', () async {
    final base = Page.create(index: 0, size: PageSize.a4Portrait).addStroke(
      Stroke.create(
        points: [
          DrawingPoint(x: 100, y: 100),
          DrawingPoint(x: 500, y: 700),
        ],
        style: StrokeStyle.pen(color: 0xFF000000, thickness: 8),
      ),
    );
    final hidden = base.copyWith(
      layers: [base.layers.first.copyWith(isVisible: false)],
    );
    final blank = Page.create(index: 0, size: PageSize.a4Portrait);
    expect(_samePixels(await _pixels(hidden), await _pixels(blank)), isTrue);
    expect(_samePixels(await _pixels(base), await _pixels(blank)), isFalse);
  });

  testGenerate('pressure strokes render with the canvas outline renderer',
      () async {
    // A fountain pen with a strong pressure ramp: the canvas draws a
    // variable-width outline, so the thin end has less ink than the thick end.
    final style = PenType.fountainPen.toStrokeStyle(
      color: 0xFF000000,
      thickness: 24,
    );
    final page = Page.create(index: 0, size: PageSize.a4Portrait).addStroke(
      Stroke.create(
        points: [
          for (var i = 0; i <= 40; i++)
            DrawingPoint(
              x: 60 + i * 12.0,
              y: 400,
              pressure: 0.05 + 0.95 * i / 40,
              timestamp: i * 16,
            ),
        ],
        style: style,
      ),
    );
    final data = await _pixels(page);
    // Thumbnail scale ~0.504: the stroke spans x 30..272 at y ~202.
    const thinBox = ui.Rect.fromLTWH(36, 180, 30, 44);
    const thickBox = ui.Rect.fromLTWH(236, 180, 30, 44);
    final thin = _inkedPixels(data, 300, thinBox);
    final thick = _inkedPixels(data, 300, thickBox);
    expect(thick, greaterThan(thin));
  });
}
