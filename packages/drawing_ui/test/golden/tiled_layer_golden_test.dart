import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/tiled_element_painter.dart';
import 'package:drawing_ui/src/canvas/unified_element_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const int _w = 400;
const int _h = 300;
const ui.Color _tint = ui.Color(0xFFFFF3C4);

List<Stroke> _strokes() {
  Stroke s(String id, StrokeStyle style, double y, {double amp = 20}) => Stroke(
        id: id,
        points: [
          for (var i = 0; i < 40; i++)
            DrawingPoint(
              x: 30 + i * 8.5,
              y: y + amp * (i % 8 < 4 ? i % 4 : 4 - i % 4) / 4,
              pressure: 0.2 + 0.8 * i / 39,
              timestamp: i * 8,
            ),
        ],
        style: style,
        createdAt: DateTime(2024),
      );
  return [
    s('pen', StrokeStyle.pen(thickness: 4), 50),
    s(
      'hl',
      StrokeStyle(
        color: 0xFF2196F3,
        thickness: 24,
        opacity: 0.5,
        nibShape: NibShape.rectangle,
        blendMode: DrawingBlendMode.multiply,
      ),
      60,
      amp: 10,
    ),
    s('brush', StrokeStyle.brush(color: 0xFF7B1FA2, thickness: 12), 170),
  ];
}

Future<ByteData> _bytes(ui.Image image) async {
  final data = await image.toByteData();
  return data!;
}

ui.Image _render(void Function(ui.Canvas) draw) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
    ui.Paint()..color = _tint,
  );
  draw(canvas);
  return recorder.endRecording().toImageSync(_w, _h);
}

void main() {
  testWidgets('tiled layer matches UnifiedElementPainter', (tester) async {
    final tiled = (await tester.runAsync(() async {
      final strokes = _strokes();
      final order = [for (final s in strokes) s.id];
      final renderer = FlutterStrokeRenderer();
      final manager = ImageCacheManager();

      final vector = _render((c) {
        UnifiedElementPainter(
          strokes: strokes,
          shapes: const [],
          images: const [],
          texts: const [],
          elementOrder: order,
          renderer: renderer,
          cacheManager: manager,
        ).paint(c, ui.Size(_w.toDouble(), _h.toDouble()));
      });

      final cache = PageTileCache(
        strokeRenderer: renderer,
        cacheManager: manager,
      )..setViewport(
          ui.Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
          1,
          interacting: false,
        );
      // Strokes arrive one by one, like pen-ups (composite path).
      for (var n = 1; n <= strokes.length; n++) {
        cache.update(
          ElementScene(
            strokes: strokes.sublist(0, n),
            elementOrder: order.sublist(0, n),
          ),
        );
      }
      final image = _render((c) {
        TiledElementPainter(cache: cache)
            .paint(c, ui.Size(_w.toDouble(), _h.toDouble()));
      });

      final a = await _bytes(vector);
      final b = await _bytes(image);
      var differing = 0;
      for (var i = 0; i < a.lengthInBytes; i += 4) {
        var d = 0;
        for (var k = 0; k < 4; k++) {
          final delta = (a.getUint8(i + k) - b.getUint8(i + k)).abs();
          if (delta > d) d = delta;
        }
        if (d > 8) differing++;
      }
      final ratio = differing / (_w * _h);
      expect(ratio, lessThan(0.005), reason: 'differing pixels: $ratio');

      cache.dispose();
      return image;
    }))!;
    await expectLater(tiled, matchesGoldenFile('tiled_layer_reference.png'));
  });
}
