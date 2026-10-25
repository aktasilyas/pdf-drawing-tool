// Ink benchmark: 1,000 synthetic strokes (mixed pens) plus a scripted active
// stroke. Prints worst / p95 frame times. Timings are informational (CI smoke).
//
// Run: ./scripts/ink_benchmark.sh   (or `flutter test test/benchmark`)
@Tags(['benchmark'])
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/drawing_controller.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/rendering/element_scene_renderer.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/tiles.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

const _strokeCount = 1000;
const _pointsPerStroke = 40;
const _committedFrames = 20;
const _activePoints = 300;
const _longStrokePoints = 2000;
const _window = 200;
const _penUps = 50;
const _pageSize = ui.Size(1200, 1600);

List<Stroke> _syntheticStrokes() {
  final rnd = math.Random(42);
  final styles = <StrokeStyle>[
    StrokeStyle.pen(thickness: 2),
    StrokeStyle.pen(color: 0xFF1565C0, thickness: 3),
    StrokeStyle.highlighter(),
    StrokeStyle.brush(),
  ];
  return List.generate(_strokeCount, (i) {
    final x0 = rnd.nextDouble() * (_pageSize.width - 200);
    final y0 = rnd.nextDouble() * (_pageSize.height - 200);
    final points = List.generate(_pointsPerStroke, (j) {
      final t = j / _pointsPerStroke;
      return DrawingPoint(
        x: x0 + t * 150,
        y: y0 + math.sin(t * math.pi * 2) * 30 + rnd.nextDouble(),
        pressure: 0.2 + 0.8 * math.sin(t * math.pi).abs(),
      );
    });
    return Stroke(
      id: 's$i',
      points: points,
      style: styles[i % styles.length],
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  });
}

class _Stats {
  _Stats(List<double> ms) : _sorted = List.of(ms)..sort();
  final List<double> _sorted;
  double get worst => _sorted.last;
  double get p95 => _sorted[((_sorted.length - 1) * 0.95).round()];
  String format(String label) =>
      '$label: worst ${worst.toStringAsFixed(2)} ms, '
      'p95 ${p95.toStringAsFixed(2)} ms (n=${_sorted.length})';
}

double _ms(Stopwatch sw) => sw.elapsedMicroseconds / 1000.0;

void main() {
  final strokes = _syntheticStrokes();
  final renderer = FlutterStrokeRenderer();

  test('ink benchmark: 1,000 strokes + scripted active stroke', () async {
    final build = <double>[];
    final raster = <double>[];
    final active = <double>[];

    // Committed page: build (record) and raster (toImage) per frame.
    for (var f = 0; f < _committedFrames; f++) {
      final sw = Stopwatch()..start();
      final recorder = ui.PictureRecorder();
      renderer.renderStrokes(ui.Canvas(recorder), strokes);
      final picture = recorder.endRecording();
      build.add(_ms(sw));

      sw.reset();
      final image = await picture.toImage(
        _pageSize.width.toInt(),
        _pageSize.height.toInt(),
      );
      raster.add(_ms(sw));
      image.dispose();
      picture.dispose();
    }

    // Active stroke: points arrive one by one, the path is rebuilt per event.
    final style = StrokeStyle.pen(thickness: 2);
    final points = <DrawingPoint>[];
    for (var i = 0; i < _activePoints; i++) {
      points.add(DrawingPoint(
        x: 100 + i * 3.0,
        y: 800 + math.sin(i / 15) * 60,
        pressure: 0.5,
      ));
      final sw = Stopwatch()..start();
      final recorder = ui.PictureRecorder();
      renderer.renderActiveStroke(ui.Canvas(recorder), points, style);
      recorder.endRecording().dispose();
      active.add(_ms(sw));
    }

    debugPrint([
      '── Ink benchmark ($_strokeCount strokes x $_pointsPerStroke pts) ──',
      _Stats(build).format('committed build '),
      _Stats(raster).format('committed raster'),
      _Stats(active).format('active stroke   '),
    ].join('\n'));

    expect(build, isNotEmpty);
    expect(active.length, _activePoints);
  });

  test('active stroke cost is independent of stroke length', () {
    // Per event: controller update + paint into a PictureRecorder.
    final styles = {
      'pen': StrokeStyle.pen(thickness: 2),
      'brush': StrokeStyle.brush(),
      'highlighter': StrokeStyle.highlighter(),
    };
    for (final entry in styles.entries) {
      List<double> run(bool incremental) {
        final controller = DrawingController();
        final times = <double>[];
        for (var i = 0; i < _longStrokePoints; i++) {
          final p = DrawingPoint(
            x: 50 + (i * 0.5) % 1000,
            y: 800 + math.sin(i / 25) * 120,
            pressure: 0.3 + 0.5 * math.sin(i / 60).abs(),
          );
          final sw = Stopwatch()..start();
          if (i == 0) {
            controller.startStroke(p, entry.value);
          } else {
            controller.addPoint(p);
          }
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          if (incremental) {
            controller.geometry.paint(canvas);
          } else {
            renderer.renderActiveStroke(
                canvas, controller.activePoints, entry.value);
          }
          recorder.endRecording().dispose();
          times.add(_ms(sw));
        }
        controller.dispose();
        return times;
      }

      for (final incremental in [false, true]) {
        final t = run(incremental);
        final first = _Stats(t.sublist(0, _window));
        final last = _Stats(t.sublist(t.length - _window));
        final label = incremental ? 'incremental' : 'legacy';
        debugPrint('active-length ${entry.key} $label: '
            'first200 p95 ${first.p95.toStringAsFixed(3)} ms, '
            'last200 p95 ${last.p95.toStringAsFixed(3)} ms, '
            'ratio ${(last.p95 / first.p95).toStringAsFixed(2)}');
        if (incremental) {
          // Generous bound: timings on shared CI machines are noisy.
          expect(last.p95, lessThan(first.p95 * 4 + 0.5));
        }
      }
    }
  });

  test('pen-up on a 1,000-stroke page: tiled cache vs legacy re-record', () {
    final base = strokes;
    final extra = List.generate(_penUps, (i) {
      final x0 = 40.0 + (i * 53) % 900;
      final y0 = 60.0 + (i * 97) % 1400;
      return Stroke(
        id: 'new$i',
        points: List.generate(
          30,
          (j) => DrawingPoint(
            x: x0 + j * 4.0,
            y: y0 + math.sin(j / 4) * 12,
            pressure: 0.5,
          ),
        ),
        style: StrokeStyle.pen(thickness: 2),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
    List<Stroke> committed(int k) => [...base, ...extra.take(k)];
    ElementScene sceneOf(List<Stroke> list) => ElementScene(
          strokes: list,
          elementOrder: [for (final s in list) s.id],
        );

    final cacheManager = ImageCacheManager();
    final cache = PageTileCache(
      strokeRenderer: renderer,
      cacheManager: cacheManager,
    );
    final page = ui.Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height);
    cache
      ..setViewport(page, 1, interacting: false)
      ..update(sceneOf(committed(0)))
      ..setViewport(page, 1, interacting: false); // warm every tile

    final tiled = <double>[];
    final legacy = <double>[];
    for (var k = 1; k <= _penUps; k++) {
      final list = committed(k);

      // Tiled: cache update + paint() recording tiles (+ vector fallback).
      var sw = Stopwatch()..start();
      cache.update(sceneOf(list));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      for (final t in cache.visibleTiles) {
        canvas.drawImage(t.image, t.rect.topLeft, ui.Paint());
      }
      for (final r in cache.vectorRects) {
        canvas.save();
        canvas.clipRect(r);
        cache.paintVectorRegion(canvas, r);
        canvas.restore();
      }
      recorder.endRecording().dispose();
      tiled.add(_ms(sw));

      // Legacy: full re-record of every element, as UnifiedElementPainter.
      sw = Stopwatch()..start();
      final legacyRecorder = ui.PictureRecorder();
      ElementSceneRenderer(
        strokes: list,
        shapes: const [],
        images: const [],
        texts: const [],
        elementOrder: [for (final s in list) s.id],
        renderer: renderer,
        cacheManager: cacheManager,
      ).paint(ui.Canvas(legacyRecorder));
      legacyRecorder.endRecording().dispose();
      legacy.add(_ms(sw));
    }

    final tiledStats = _Stats(tiled);
    debugPrint([
      '── Pen-up benchmark ($_strokeCount strokes, $_penUps pen-ups) ──',
      'pen-up tiled : ${tiledStats.format('').substring(2)}',
      'pen-up legacy: ${_Stats(legacy).format('').substring(2)}',
      'pen-up vector tiles: ${cache.vectorRects.length}, '
          'raster tiles: ${cache.visibleTiles.length}',
    ].join('\n'));
    cache.dispose();

    // Spec target is 16 ms; bound is generous for noisy headless machines.
    expect(tiledStats.worst, lessThan(16.0));
  });
}
