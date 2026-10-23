// Ink benchmark: 1,000 synthetic strokes (mixed pens) plus a scripted active
// stroke. Prints worst / p95 frame times. Timings are informational (CI smoke).
//
// Run: ./scripts/ink_benchmark.sh   (or `flutter test test/benchmark`)
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

const _strokeCount = 1000;
const _pointsPerStroke = 40;
const _committedFrames = 20;
const _activePoints = 300;
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
}
