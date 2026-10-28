import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_raster_layer_renderer.dart';
import 'package:flutter/painting.dart' show Offset;
import 'package:flutter_test/flutter_test.dart';

const _w = 200.0;
const _h = 120.0;

const _red = 0xFFFF0000;
const _blue = 0xFF0000FF;

Shape _filled(ShapeType type, {int color = _red, String? id}) => Shape(
      id: id ?? 'shape-${type.name}',
      type: type,
      startPoint: DrawingPoint(x: 20, y: 20),
      endPoint: DrawingPoint(x: 120, y: 100),
      style: StrokeStyle.pen(color: color, thickness: 4),
      isFilled: true,
      fillColor: color,
    );

/// Expects [px] to be opaque and within 2 of ([r], [g], [b]) per channel.
void _expectRgba(List<int> px, int r, int g, int b) {
  final expected = [r, g, b, 255];
  for (var i = 0; i < 4; i++) {
    expect(px[i], closeTo(expected[i], 2), reason: 'channel $i of $px');
  }
}

/// RGBA of pixel ([x], [y]) at scale 1.
List<int> _px(PdfRawImage img, int x, int y) {
  final i = (y * img.width + x) * 4;
  return img.bytes.sublist(i, i + 4);
}

Future<PdfRawImage> _render(Layer layer) async =>
    (await PdfRasterLayerRenderer().renderLayer(layer, _w, _h, 1))!;

void main() {
  group('PdfRasterLayerRenderer shapes', () {
    // Bounding-box corner (inside the rect, outside the polygon) must stay
    // empty: the old fallback filled the whole rectangle.
    for (final type in [
      ShapeType.star,
      ShapeType.pentagon,
      ShapeType.hexagon,
      ShapeType.plus,
      ShapeType.triangle,
      ShapeType.diamond,
    ]) {
      test('${type.name} rasterizes its outline, not its bounding box',
          () async {
        final img = await _render(Layer.empty('l').addShape(_filled(type)));
        expect(_px(img, 24, 24)[3], 0, reason: 'corner must be empty');
        final centre = _px(img, 70, 60);
        expect(centre[0], greaterThan(200), reason: 'centre is painted red');
        expect(centre[3], greaterThan(200));
      });
    }
  });

  group('PdfRasterLayerRenderer z-order', () {
    test('follows elementOrder across element types', () async {
      // A shape drawn after a stroke must cover it (old fallback painted all
      // strokes first, then all shapes, whatever the order).
      final stroke = Stroke(
        id: 'stroke',
        points: [
          for (var x = 10; x <= 190; x += 10)
            DrawingPoint(x: x.toDouble(), y: 60),
        ],
        style: StrokeStyle.pen(color: _blue, thickness: 12).copyWith(
          pressureSensitive: false,
          dynamics: StrokeDynamics.none,
        ),
        createdAt: DateTime(2026),
      );
      final shape = _filled(ShapeType.rectangle, id: 'rect');

      // Insertion order: rect, then stroke.
      final strokeOnTop = Layer.empty('l').addShape(shape).addStroke(stroke);
      final shapeOnTop = strokeOnTop.copyWith(elementOrder: ['stroke', 'rect']);

      final a = _px(await _render(strokeOnTop), 70, 60);
      expect(a[2], greaterThan(200), reason: 'stroke (blue) on top');
      expect(a[0], lessThan(60));

      final b = _px(await _render(shapeOnTop), 70, 60);
      expect(b[0], greaterThan(200), reason: 'rect (red) on top');
      expect(b[2], lessThan(60));
    });
  });

  group('PdfRasterLayerRenderer sticky notes', () {
    test('a sticky note is painted with its colour', () async {
      final note = StickyNote(
        id: 'n',
        x: 40,
        y: 20,
        width: 100,
        height: 80,
        color: 0xFFFFF3CD,
      );
      final renderer = PdfRasterLayerRenderer();
      final img = (await renderer.renderStickyNotes([note], _w, _h, 1))!;
      final inside = _px(img, 110, 85);
      _expectRgba(inside, 0xFF, 0xF3, 0xCD);
      expect(_px(img, 190, 110)[3], 0, reason: 'outside the note is empty');
    });

    test('renderLayer includes the layer sticky notes', () async {
      final note = StickyNote(
          id: 'n', x: 40, y: 20, width: 100, height: 80, color: 0xFF00FF00);
      final img = await _render(Layer.empty('l').addStickyNote(note));
      _expectRgba(_px(img, 110, 85), 0x00, 0xFF, 0x00);
    });
  });

  group('PdfRasterLayerRenderer origin', () {
    // Infinite canvas: content at negative page coordinates is shifted by
    // the export origin into the image.
    final note = StickyNote(
        id: 'n', x: -150, y: 10, width: 100, height: 80, color: 0xFF00FF00);

    test('renderLayer translates content by origin', () async {
      final img = (await PdfRasterLayerRenderer().renderLayer(
        Layer.empty('l').addStickyNote(note),
        _w,
        _h,
        1,
        origin: const Offset(170, 0),
      ))!;
      // Note spans x 20..120 after the shift.
      _expectRgba(_px(img, 70, 50), 0x00, 0xFF, 0x00);
      expect(_px(img, 150, 50)[3], 0, reason: 'right of the note is empty');
    });

    test('renderStickyNotes translates notes by origin', () async {
      final img = (await PdfRasterLayerRenderer().renderStickyNotes(
          [note], _w, _h, 1,
          origin: const Offset(170, 0)))!;
      _expectRgba(_px(img, 70, 50), 0x00, 0xFF, 0x00);
    });

    test('without origin the note stays outside the image', () async {
      final img = (await PdfRasterLayerRenderer()
          .renderStickyNotes([note], _w, _h, 1))!;
      expect(_px(img, 70, 50)[3], 0);
    });
  });
}
