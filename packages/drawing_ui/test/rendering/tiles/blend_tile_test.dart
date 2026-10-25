import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/tiled_element_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const int _size = 600;
const ui.Rect _page = ui.Rect.fromLTWH(0, 0, 600, 600);
const ui.Color _paper = ui.Color(0xFFFFF3C4);

Stroke _stroke(
  String id,
  double y,
  StrokeStyle style, {
  double x = 40,
}) =>
    Stroke(
      id: id,
      points: [
        for (var i = 0; i < 30; i++)
          DrawingPoint(
            x: x + i * 6.0,
            y: y + (i % 6) * 4.0,
            pressure: 0.3 + 0.7 * i / 29,
            timestamp: i * 8,
          ),
      ],
      style: style,
      createdAt: DateTime(2024),
    );

StrokeStyle _blend(DrawingBlendMode mode, {int color = 0xFF2196F3}) =>
    StrokeStyle(
      color: color,
      thickness: 24,
      opacity: 0.3,
      nibShape: NibShape.rectangle,
      blendMode: mode,
    );

ElementScene _scene(List<Stroke> strokes) => ElementScene(
      strokes: strokes,
      elementOrder: [for (final s in strokes) s.id],
    );

PageTileCache _cache() => PageTileCache(
      strokeRenderer: FlutterStrokeRenderer(),
      cacheManager: ImageCacheManager(),
    )..setViewport(_page, 1, interacting: false);

Future<Uint8List> _pixels(void Function(ui.Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(_page, ui.Paint()..color = _paper);
  draw(canvas);
  final image = recorder.endRecording().toImageSync(_size, _size);
  final data = await image.toByteData();
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<Uint8List> _tiled(PageTileCache cache) => _pixels(
      (c) =>
          TiledElementPainter(cache: cache).paint(c, const ui.Size(600, 600)),
    );

Future<Uint8List> _vector(ElementScene scene) => _pixels(
      (c) => buildSceneRenderer(
        scene,
        FlutterStrokeRenderer(),
        ImageCacheManager(),
      ).paintRegion(c, _page),
    );

double _diffRatio(Uint8List a, Uint8List b) {
  var bad = 0;
  for (var i = 0; i < a.length; i += 4) {
    var worst = 0;
    for (var c = 0; c < 4; c++) {
      final d = (a[i + c] - b[i + c]).abs();
      if (d > worst) worst = d;
    }
    if (worst > 8) bad++;
  }
  return bad / (a.length / 4);
}

void main() {
  for (final mode in [DrawingBlendMode.multiply, DrawingBlendMode.screen]) {
    testWidgets('$mode tiles match vectors and are rastered', (tester) async {
      await tester.runAsync(() async {
        final pen = StrokeStyle.pen(thickness: 4);
        final strokes = [
          _stroke('ink', 90, pen),
          _stroke('hl', 100, _blend(mode)),
          // Normal stroke above the highlighter (z-order matters).
          _stroke('top', 110, StrokeStyle.pen(color: 0xFFD32F2F, thickness: 6)),
          _stroke('hl2', 105, _blend(mode, color: 0xFF4CAF50), x: 120),
        ];
        final cache = _cache();
        // Pen-up by pen-up: exercises plain->pair and pair->pair composites.
        for (var n = 1; n <= strokes.length; n++) {
          cache.update(_scene(strokes.sublist(0, n)));
          expect(cache.vectorRects, isEmpty, reason: 'after $n strokes');
          final ratio = _diffRatio(
            await _tiled(cache),
            await _vector(_scene(strokes.sublist(0, n))),
          );
          expect(ratio, lessThan(0.005), reason: 'after $n strokes: $ratio');
        }
        expect(cache.visibleTiles, isNotEmpty);

        // Cold build of the whole scene and an undo (dirty path).
        final cold = _cache()..update(_scene(strokes));
        expect(cold.vectorRects, isEmpty);
        expect(
          _diffRatio(await _tiled(cold), await _vector(_scene(strokes))),
          lessThan(0.005),
        );
        cache.update(_scene(strokes.sublist(0, 2)));
        expect(cache.vectorRects, isEmpty);
        expect(
          _diffRatio(
            await _tiled(cache),
            await _vector(_scene(strokes.sublist(0, 2))),
          ),
          lessThan(0.005),
        );
        cache.dispose();
        cold.dispose();
      });
    });
  }

  testWidgets('overlay, darken and lighten stay vectors', (tester) async {
    for (final mode in [
      DrawingBlendMode.overlay,
      DrawingBlendMode.darken,
      DrawingBlendMode.lighten,
    ]) {
      final cache = _cache()..update(_scene([_stroke('b', 100, _blend(mode))]));
      expect(cache.visibleTiles, isEmpty, reason: '$mode');
      expect(cache.vectorRects, isNotEmpty, reason: '$mode');
      cache.dispose();
    }
  });

  testWidgets('blend tile images are all disposed', (tester) async {
    final cache = _cache()
      ..update(_scene([_stroke('hl', 100, _blend(DrawingBlendMode.multiply))]));
    final tile = cache.visibleTiles.first;
    expect(tile.multiplyImage, isNotNull);
    final images = [tile.image, tile.multiplyImage!];
    cache.update(_scene(const []));
    expect(images.every((i) => i.debugDisposed), isTrue);
    cache.dispose();
  });
}
