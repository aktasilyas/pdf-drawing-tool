import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Rect;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const double _pageW = 1024;
const double _pageH = 1024;
const Rect _page = Rect.fromLTWH(0, 0, _pageW, _pageH);

Stroke _s(String id, double x, double y, {double thickness = 3}) => Stroke(
      id: id,
      points: [
        DrawingPoint(x: x, y: y),
        DrawingPoint(x: x + 24, y: y + 16),
        DrawingPoint(x: x + 30, y: y + 40),
      ],
      style: StrokeStyle(color: 0xFF112233, thickness: thickness),
      createdAt: DateTime(2024),
    );

ElementScene _scene(
  List<Stroke> strokes, {
  Map<String, List<int>> pixel = const {},
}) =>
    ElementScene(
      strokes: strokes,
      elementOrder: [for (final s in strokes) s.id],
      pixelEraserPreview: pixel,
    );

PageTileCache _cache({int budget = 64 << 20}) => PageTileCache(
      strokeRenderer: FlutterStrokeRenderer(),
      cacheManager: ImageCacheManager(),
      budgetBytes: budget,
    );

/// Two strokes in each of the four 512px tiles (q* first, then r*).
List<Stroke> _quadrants() => [
      _s('q00', 100, 100),
      _s('q10', 700, 100),
      _s('q01', 100, 700),
      _s('q11', 700, 700),
      _s('r00', 200, 200),
      _s('r10', 800, 200),
      _s('r01', 200, 800),
      _s('r11', 800, 800),
    ];

Future<Uint8List> _bytes(ui.Image image) async {
  final data = await image.toByteData();
  return data!.buffer.asUint8List();
}

Future<Uint8List> _renderTiled(
  PageTileCache cache,
  double scale,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(scale);
  for (final t in cache.visibleTiles) {
    canvas.drawImageRect(
      t.image,
      ui.Rect.fromLTWH(
        0,
        0,
        t.image.width.toDouble(),
        t.image.height.toDouble(),
      ),
      t.rect,
      ui.Paint(),
    );
  }
  final img = recorder.endRecording().toImageSync(
        (_pageW * scale).round(),
        (_pageH * scale).round(),
      );
  final bytes = await _bytes(img);
  img.dispose();
  return bytes;
}

Future<Uint8List> _renderVector(ElementScene scene, double scale) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(scale);
  ElementSceneRenderer(
    strokes: scene.strokes,
    shapes: scene.shapes,
    images: scene.images,
    texts: scene.texts,
    elementOrder: scene.elementOrder,
    renderer: FlutterStrokeRenderer(),
    cacheManager: ImageCacheManager(),
    excludedStrokeIds: scene.excludedIds,
    pixelEraserPreview: scene.pixelEraserPreview,
    strokeEraserPreview: scene.strokeEraserPreview,
  ).paint(canvas);
  final img = recorder.endRecording().toImageSync(
        (_pageW * scale).round(),
        (_pageH * scale).round(),
      );
  final bytes = await _bytes(img);
  img.dispose();
  return bytes;
}

double _diffRatio(Uint8List a, Uint8List b) {
  expect(a.length, b.length);
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
  group('A2 pen-up records at most one element', () {
    for (final n in [10, 100, 1000]) {
      test('n = $n', () {
        final cache = _cache()..setViewport(_page, 1, interacting: false);
        final strokes = [
          for (var i = 0; i < n; i++)
            _s('s$i', (i % 30) * 32.0, ((i ~/ 30) % 30) * 32.0),
        ];
        cache.update(_scene(strokes));
        final before = cache.debugRasterCount;

        cache.update(_scene([...strokes, _s('new', 520, 520)]));

        expect(cache.debugLastRecordedElements, lessThanOrEqualTo(1));
        expect(cache.debugRasterCount, greaterThan(before));
        // New stroke (520..550) only touches tile (1,1).
        expect(cache.debugRasterizedKeys, [const TileKey(1, 1)]);
        cache.dispose();
      });
    }
  });

  group('A3 invalidation scope', () {
    ui.Image? imageOf(PageTileCache c, TileKey k) {
      for (final t in c.visibleTiles) {
        if (t.key == k) return t.image;
      }
      return null;
    }

    test('undo re-rasterizes only the intersecting tile', () {
      final cache = _cache()..setViewport(_page, 1, interacting: false);
      final qs = _quadrants();
      cache.update(_scene(qs));
      final keep = {
        for (final k in const [TileKey(0, 0), TileKey(1, 0), TileKey(0, 1)])
          k: imageOf(cache, k),
      };
      final old = imageOf(cache, const TileKey(1, 1));

      cache.update(_scene(qs.sublist(0, 7)));

      expect(cache.debugRasterizedKeys, [const TileKey(1, 1)]);
      for (final e in keep.entries) {
        expect(identical(imageOf(cache, e.key), e.value), isTrue);
      }
      expect(imageOf(cache, const TileKey(1, 1)), isNot(same(old)));
      cache.dispose();
    });

    test('erasing a middle stroke keeps other tile images', () {
      final cache = _cache()..setViewport(_page, 1, interacting: false);
      final qs = _quadrants();
      cache.update(_scene(qs));
      final others = {
        for (final k in const [TileKey(0, 0), TileKey(1, 1), TileKey(0, 1)])
          k: imageOf(cache, k),
      };

      cache.update(_scene([qs[0], ...qs.sublist(2)]));

      expect(cache.debugRasterizedKeys, [const TileKey(1, 0)]);
      for (final e in others.entries) {
        expect(identical(imageOf(cache, e.key), e.value), isTrue);
      }
      cache.dispose();
    });

    test('stroke spanning two tiles dirties both', () {
      final cache = _cache()..setViewport(_page, 1, interacting: false);
      final span = _s('span', 500, 100);
      final qs = _quadrants();
      cache.update(_scene([span, ...qs]));

      cache.update(_scene(qs));

      expect(
        cache.debugRasterizedKeys.toSet(),
        {const TileKey(0, 0), const TileKey(1, 0)},
      );
      cache.dispose();
    });
  });

  group('eviction and disposal', () {
    test('LRU eviction keeps visible tiles and honours the budget', () {
      // One 512x512 RGBA tile is 1 MiB.
      final cache = _cache(budget: 2 << 20)
        ..setViewport(_page, 1, interacting: false);
      cache.update(_scene(_quadrants()));
      expect(cache.visibleTiles.length, 4); // visible are never evicted

      cache.setViewport(const Rect.fromLTWH(0, 0, 500, 500), 1,
          interacting: false);
      expect(cache.cachedBytes, lessThanOrEqualTo(2 << 20));
      expect(cache.visibleTiles.length, 1);
      cache.dispose();
    });

    test('replaced and disposed images are disposed', () {
      final cache = _cache()..setViewport(_page, 1, interacting: false);
      final qs = _quadrants();
      cache.update(_scene(qs));
      final old = cache.visibleTiles.firstWhere(
        (t) => t.key == const TileKey(0, 0),
      );
      final oldImage = old.image;

      cache.update(_scene(qs.sublist(1)));
      expect(oldImage.debugDisposed, isTrue);

      final live = [for (final t in cache.visibleTiles) t.image];
      cache.dispose();
      expect(live.every((i) => i.debugDisposed), isTrue);
    });
  });

  group('A5 parity with vector rendering', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('add/undo/erase/pixel-erase at scale $scale', (tester) async {
        await tester.runAsync(() async {
          final cache = _cache()..setViewport(_page, scale, interacting: false);
          final all = [
            for (var i = 0; i < 40; i++)
              _s('p$i', 20.0 + (i * 53) % 940, 30.0 + (i * 97) % 940,
                  thickness: 2 + (i % 5).toDouble()),
            // Crosses a tile edge at both scales.
            _s('edge', 500, 500, thickness: 6),
          ];
          final steps = <ElementScene>[
            _scene(all.sublist(0, 20)),
            _scene(all.sublist(0, 30)),
            _scene(all),
            _scene(all.sublist(0, 40)), // undo
            _scene([...all.sublist(0, 10), ...all.sublist(11, 40)]), // erase
            _scene(
              [...all.sublist(0, 10), ...all.sublist(11, 40)],
              pixel: {
                'p20': [1]
              },
            ),
          ];

          for (final scene in steps) {
            cache.update(scene);
            final tiled = await _renderTiled(cache, scale);
            final vector = await _renderVector(scene, scale);
            expect(_diffRatio(tiled, vector), lessThan(0.005));
          }
          cache.dispose();
        });
      });
    }
  });
}
