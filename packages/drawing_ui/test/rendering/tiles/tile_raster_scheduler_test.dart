import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Rect;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect _page = Rect.fromLTWH(0, 0, 1024, 1024);

Stroke _s(String id, double x, double y) => Stroke(
      id: id,
      points: [
        DrawingPoint(x: x, y: y),
        DrawingPoint(x: x + 24, y: y + 16),
        DrawingPoint(x: x + 30, y: y + 40),
      ],
      style: StrokeStyle(color: 0xFF112233, thickness: 4),
      createdAt: DateTime(2024),
    );

ElementScene _scene(List<Stroke> strokes) => ElementScene(
      strokes: strokes,
      elementOrder: [for (final s in strokes) s.id],
    );

PageTileCache _cache() => PageTileCache(
      strokeRenderer: FlutterStrokeRenderer(),
      cacheManager: ImageCacheManager(),
    );

/// A grid of strokes so that many tiles hold content at scale 2.
List<Stroke> _many() => [
      for (var i = 0; i < 16; i++)
        _s('s$i', 40.0 + (i % 4) * 250, 40.0 + (i ~/ 4) * 250),
    ];

/// Drives frames by hand; every clock read advances time by [tick].
class _FakeFrames {
  _FakeFrames();

  final Duration tick = const Duration(milliseconds: 2);
  Duration time = Duration.zero;
  void Function(Duration)? pending;
  int scheduled = 0;

  Duration now() {
    time += tick;
    return time;
  }

  void schedule(void Function(Duration) cb) {
    scheduled++;
    pending = cb;
  }

  bool runFrame() {
    final cb = pending;
    if (cb == null) return false;
    pending = null;
    cb(time);
    return true;
  }
}

Future<Uint8List> _render(
  void Function(ui.Canvas) paint,
  double scale,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..scale(scale);
  paint(canvas);
  final img = recorder.endRecording().toImageSync(
        (1024 * scale).round(),
        (1024 * scale).round(),
      );
  final data = await img.toByteData();
  img.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  late PageTileCache cache;
  late _FakeFrames frames;
  late TileRasterScheduler scheduler;

  setUp(() {
    cache = _cache()..setViewport(_page, 1, interacting: false);
    cache.update(_scene(_many()));
    frames = _FakeFrames();
    scheduler = TileRasterScheduler(
      cache: cache,
      now: frames.now,
      scheduleFrame: frames.schedule,
    );
  });

  tearDown(() {
    scheduler.dispose();
    cache.dispose();
  });

  test('no raster while interacting, even when the scale changes', () {
    final before = cache.debugRasterCount;
    cache.setViewport(_page, 1.5, interacting: true);
    cache.setViewport(_page, 2, interacting: true);
    expect(cache.debugRasterCount, before);
    expect(cache.hasPending, isFalse);
    expect(frames.pending, isNull);
    expect(cache.visibleTiles, isNotEmpty); // old tiles keep being drawn
  });

  test('settling defers raster to frames and keeps old tiles as fallback', () {
    final before = cache.debugRasterCount;
    final oldImages = [for (final t in cache.visibleTiles) t.image];

    cache.setViewport(_page, 2, interacting: false);

    expect(cache.debugRasterCount, before);
    expect(cache.hasPending, isTrue);
    expect(cache.visibleTiles, isEmpty);
    expect(cache.legacyTiles.map((t) => t.image), oldImages);
    expect(oldImages.every((i) => !i.debugDisposed), isTrue);
    expect(frames.pending, isNotNull);
  });

  test('re-rasterizes progressively within the frame budget', () {
    cache.setViewport(_page, 2, interacting: false);
    final total = cache.pendingCount;
    expect(total, greaterThan(4));

    var frameCount = 0;
    var last = total;
    while (frames.runFrame()) {
      frameCount++;
      final done = last - cache.pendingCount;
      // 2 ms per clock read, 6 ms budget -> at most 3 tiles per frame, and
      // always at least one so progress is guaranteed.
      expect(done, inInclusiveRange(1, 3));
      last = cache.pendingCount;
      expect(frameCount, lessThan(100));
    }
    expect(frameCount, greaterThan(1));
    expect(cache.hasPending, isFalse);
  });

  test('old-scale images are disposed once the last tile is ready', () {
    final oldImages = [for (final t in cache.visibleTiles) t.image];
    cache.setViewport(_page, 2, interacting: false);

    while (cache.pendingCount > 1) {
      frames.runFrame();
      if (cache.pendingCount > 1) {
        expect(oldImages.any((i) => i.debugDisposed), isFalse);
      }
    }
    while (frames.runFrame()) {}
    expect(oldImages.every((i) => i.debugDisposed), isTrue);
    expect(cache.legacyTiles, isEmpty);
  });

  test('rasterizes tiles nearest to the viewport centre first', () {
    const view = Rect.fromLTWH(0, 0, 1024, 1024);
    cache.setViewport(view, 2, interacting: false);
    final firstKeys = <TileKey>[];
    cache.addListener(() => firstKeys.addAll(cache.debugRasterizedKeys));
    frames.runFrame();
    final grid = TileGrid(scale: 2);
    double dist(TileKey k) =>
        (grid.rectOf(k).center - view.center).distanceSquared;
    final remaining = cache.debugPendingKeys;
    for (final k in firstKeys.toSet()) {
      for (final r in remaining) {
        expect(dist(k), lessThanOrEqualTo(dist(r)));
      }
    }
  });

  test('scale compare uses an epsilon', () {
    final before = cache.debugRasterCount;
    cache.setViewport(_page, 1 + 1e-9, interacting: false);
    expect(cache.hasPending, isFalse);
    expect(cache.debugRasterCount, before);
  });

  test('a scene update during the wait never shows stale tiles', () {
    cache.setViewport(_page, 2, interacting: false);
    final undone = _many()..removeLast();
    cache.update(_scene(undone));
    expect(cache.hasPending, isFalse);
    expect(cache.legacyTiles, isEmpty);
    expect(cache.visibleTiles, isNotEmpty);
  });

  testWidgets('settled tiles match a vector render at the new scale', (
    tester,
  ) async {
    await tester.runAsync(() async {
      cache.setViewport(_page, 2, interacting: false);
      while (frames.runFrame()) {}

      final tiled = await _render((canvas) {
        for (final t in cache.visibleTiles) {
          canvas.drawImageRect(
            t.image,
            Rect.fromLTWH(
              0,
              0,
              t.image.width.toDouble(),
              t.image.height.toDouble(),
            ),
            t.rect,
            ui.Paint(),
          );
        }
      }, 2);
      final vector = await _render(
        (canvas) => buildSceneRenderer(
          _scene(_many()),
          FlutterStrokeRenderer(),
          ImageCacheManager(),
        ).paint(canvas),
        2,
      );
      var bad = 0;
      for (var i = 0; i < tiled.length; i++) {
        if ((tiled[i] - vector[i]).abs() > 8) bad++;
      }
      expect(bad / tiled.length, lessThan(0.005));
    });
  });
}
