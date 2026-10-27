import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/services/selection_capture_service.dart';
import 'package:flutter_test/flutter_test.dart';

// "Save selection as image" must look like the canvas (#305): real pen
// geometry and the page's own template, through the shared painters.

const _scale = SelectionCaptureService.exportScale;

Selection _rectSelection(
  BoundingBox bounds, {
  List<String> strokes = const [],
}) =>
    Selection.create(
      type: SelectionType.rectangle,
      selectedStrokeIds: strokes,
      bounds: bounds,
    );

Stroke _line(String id, double y, {double x0 = 20, double x1 = 100}) => Stroke(
      id: id,
      points: [
        for (var x = x0; x <= x1; x += 10) DrawingPoint(x: x, y: y),
      ],
      style: StrokeStyle.pen(color: 0xFF000000, thickness: 6).copyWith(
        pressureSensitive: false,
        dynamics: StrokeDynamics.none,
      ),
      createdAt: DateTime(2026),
    );

PageBackground _template(TemplatePattern pattern) => PageBackground(
      type: BackgroundType.template,
      templatePattern: pattern,
      templateSpacingMm: pattern.defaultSpacingMm,
      templateLineWidth: pattern.defaultLineWidth,
      lineColor: 0xFF9E9E9E,
    );

typedef _Raster = ({ByteData data, int width, int height});

Future<_Raster> _render(
  Selection selection,
  Layer layer, {
  PageBackground? background,
  double padding = 16,
}) async {
  final cache = ImageCacheManager();
  try {
    final image = await SelectionCaptureService.renderSelection(
      selection: selection,
      layer: layer,
      cacheManager: cache,
      background: background,
      pageSize: const ui.Size(595, 842),
      padding: padding,
    );
    expect(image, isNotNull);
    final data = (await image!.toByteData())!;
    final raster = (data: data, width: image.width, height: image.height);
    image.dispose();
    return raster;
  } finally {
    cache.dispose();
  }
}

/// Pixels in [box] (image coordinates) that are not near-white.
int _inked(_Raster r, ui.Rect box) {
  var n = 0;
  for (var y = box.top.toInt(); y < box.bottom.toInt(); y++) {
    for (var x = box.left.toInt(); x < box.right.toInt(); x++) {
      final i = (y * r.width + x) * 4;
      if (r.data.getUint8(i) < 200 ||
          r.data.getUint8(i + 1) < 200 ||
          r.data.getUint8(i + 2) < 200) {
        n++;
      }
    }
  }
  return n;
}

bool _same(_Raster a, _Raster b) {
  if (a.data.lengthInBytes != b.data.lengthInBytes) return false;
  for (var i = 0; i < a.data.lengthInBytes; i++) {
    if (a.data.getUint8(i) != b.data.getUint8(i)) return false;
  }
  return true;
}

void testRender(String name, Future<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(body);
  });
}

void main() {
  const bounds = BoundingBox(left: 10, top: 20, right: 110, bottom: 70);

  testRender('output is (bounds + 2 x padding) x export scale', () async {
    final layer = Layer.empty('l').addStroke(_line('a', 30));
    final r = await _render(_rectSelection(bounds, strokes: ['a']), layer);
    expect(r.width, ((100 + 32) * _scale).ceil());
    expect(r.height, ((50 + 32) * _scale).ceil());
  });

  testRender('only selected elements are drawn', () async {
    final layer = Layer.empty('l')
        .addStroke(_line('selected', 30))
        .addStroke(_line('other', 60));
    final r = await _render(
      _rectSelection(bounds, strokes: ['selected']),
      layer,
    );
    // Page (x, y) maps to ((x - 10 + 16) * 3, (y - 20 + 16) * 3).
    ui.Rect around(double y) => ui.Rect.fromLTWH((40 - 10 + 16) * _scale,
        (y - 20 + 16 - 4) * _scale, 40 * _scale, 8 * _scale);
    expect(_inked(r, around(30)), greaterThan(0), reason: 'selected stroke');
    expect(_inked(r, around(60)), 0, reason: 'unselected stroke');
  });

  testRender('the page template is painted, not a plain grid', () async {
    const area = BoundingBox(left: 0, top: 0, right: 300, bottom: 300);
    final empty = Layer.empty('l');
    Future<_Raster> on(TemplatePattern p) => _render(
          _rectSelection(area),
          empty,
          background: _template(p),
          padding: 0,
        );
    final blank = await on(TemplatePattern.blank);
    final cornell = await on(TemplatePattern.cornell);
    final grid = await on(TemplatePattern.smallGrid);
    expect(_same(cornell, blank), isFalse, reason: 'cornell renders nothing');
    expect(_same(cornell, grid), isFalse, reason: 'cornell drawn as a grid');
  });

  testRender('pressure strokes keep the canvas outline geometry', () async {
    // Fountain pen with a strong pressure ramp: the canvas draws a
    // variable-width outline, so the thin end has less ink than the thick
    // end (a plain drawPath would give both ends the same width).
    final ramp = Stroke.create(
      points: [
        for (var i = 0; i <= 40; i++)
          DrawingPoint(
            x: 60 + i * 12.0,
            y: 400,
            pressure: 0.05 + 0.95 * i / 40,
            timestamp: i * 16,
          ),
      ],
      style: PenType.fountainPen.toStrokeStyle(
        color: 0xFF000000,
        thickness: 24,
      ),
    );
    final layer = Layer.empty('l').addStroke(ramp);
    final r = await _render(
      _rectSelection(
        const BoundingBox(left: 40, top: 360, right: 560, bottom: 440),
        strokes: [ramp.id],
      ),
      layer,
      padding: 0,
    );
    // Page x 60..90 and 510..540 (image x = (page x - 40) * 3).
    final thin = _inked(r, ui.Rect.fromLTWH(20 * _scale, 0, 30 * _scale, 240));
    final thick =
        _inked(r, ui.Rect.fromLTWH(470 * _scale, 0, 30 * _scale, 240));
    expect(thin, greaterThan(0));
    expect(thick, greaterThan(thin));
    // No ink outside the stroke's vertical extent (thickness 24 at y 400).
    expect(_inked(r, ui.Rect.fromLTWH(0, 0, r.width.toDouble(), 30)), 0);
  });
}
