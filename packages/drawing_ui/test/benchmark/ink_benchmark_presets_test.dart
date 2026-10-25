// Ink benchmark for the v2 presets: 1,000 strokes alternating fountain and
// brush (tapered outlines) plus a scripted active fountain stroke.
// Timings are informational; run via ./scripts/ink_benchmark.sh.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/drawing_controller.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

const _strokeCount = 1000;
const _pointsPerStroke = 40;
const _frames = 20;
const _activePoints = 600;
const _pageSize = ui.Size(1200, 1600);

List<Stroke> _strokes() {
  final rnd = math.Random(7);
  final styles = [
    PenType.fountainPen.toStrokeStyle(color: 0xFF1A237E, thickness: 3),
    PenType.brushPen.toStrokeStyle(color: 0xFF7B1FA2, thickness: 8),
  ];
  return List.generate(_strokeCount, (i) {
    final x0 = rnd.nextDouble() * (_pageSize.width - 200);
    final y0 = rnd.nextDouble() * (_pageSize.height - 200);
    return Stroke(
      id: 's$i',
      points: List.generate(_pointsPerStroke, (j) {
        final t = j / _pointsPerStroke;
        return DrawingPoint(
          x: x0 + t * 150,
          y: y0 + math.sin(t * math.pi * 2) * 30 + rnd.nextDouble(),
          pressure: 0.2 + 0.8 * math.sin(t * math.pi).abs(),
        );
      }),
      style: styles[i % 2],
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  });
}

String _fmt(String label, List<double> ms) {
  final s = List.of(ms)..sort();
  final p95 = s[((s.length - 1) * 0.95).round()];
  return '$label: worst ${s.last.toStringAsFixed(2)} ms, '
      'p95 ${p95.toStringAsFixed(2)} ms (n=${s.length})';
}

double _ms(Stopwatch sw) => sw.elapsedMicroseconds / 1000.0;

void main() {
  test('ink benchmark presets: 1,000 fountain/brush strokes', () async {
    final strokes = _strokes();
    final renderer = FlutterStrokeRenderer();
    final build = <double>[];
    final raster = <double>[];
    for (var f = 0; f < _frames; f++) {
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

    final controller = DrawingController();
    final active = <double>[];
    final style = PenType.fountainPen.toStrokeStyle(color: 0xFF1A237E);
    for (var i = 0; i < _activePoints; i++) {
      final p = DrawingPoint(
        x: 50 + (i * 1.5) % 1000,
        y: 800 + math.sin(i / 25) * 120,
        pressure: 0.3 + 0.5 * math.sin(i / 60).abs(),
      );
      final sw = Stopwatch()..start();
      if (i == 0) {
        controller.startStroke(p, style);
      } else {
        controller.addPoint(p);
      }
      final recorder = ui.PictureRecorder();
      controller.geometry.paint(ui.Canvas(recorder));
      recorder.endRecording().dispose();
      active.add(_ms(sw));
    }
    controller.dispose();

    debugPrint([
      '── Presets benchmark ($_strokeCount fountain/brush strokes) ──',
      _fmt('committed build  ', build),
      _fmt('committed raster ', raster),
      _fmt('active fountain  ', active),
    ].join('\n'));

    expect(build, isNotEmpty);
    expect(active.length, _activePoints);
  });
}
