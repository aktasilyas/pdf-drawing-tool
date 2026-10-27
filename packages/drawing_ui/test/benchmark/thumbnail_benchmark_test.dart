// Thumbnail benchmark: generate a 150x200 thumbnail of the 1,000-stroke
// benchmark page (same synthetic strokes as ink_benchmark_test.dart) with
// ThumbnailGenerator (canvas painters), next to the pre-#256 simplified
// polyline renderer as a baseline. Timings are informational (CI smoke).
@Tags(['benchmark'])
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

const _strokeCount = 1000;
const _pointsPerStroke = 40;
const _runs = 10;

Page _benchmarkPage() {
  final rnd = math.Random(42);
  final highlighter = StrokeStyle(
    color: 0xFFFFEB3B,
    thickness: 20,
    opacity: 0.5,
    nibShape: NibShape.rectangle,
    blendMode: DrawingBlendMode.multiply,
  );
  final styles = <StrokeStyle>[
    highlighter,
    highlighter,
    highlighter,
    StrokeStyle.pen(thickness: 2),
    StrokeStyle.pen(thickness: 2),
    StrokeStyle.pen(thickness: 2),
    StrokeStyle.pen(color: 0xFF1565C0, thickness: 3),
    StrokeStyle.pen(color: 0xFF1565C0, thickness: 3),
    StrokeStyle.brush(),
    StrokeStyle.brush(),
  ];
  final page = Page.create(
    index: 0,
    size: const PageSize(width: 1200, height: 1600),
  );
  final strokes = List.generate(_strokeCount, (i) {
    final x0 = rnd.nextDouble() * 1000;
    final y0 = rnd.nextDouble() * 1400;
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
      style: styles[i % styles.length],
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  });
  return page.copyWith(
    layers: [page.layers.first.copyWith(strokes: strokes)],
  );
}

/// The pre-#256 thumbnail renderer: constant-width polylines on white.
Future<Uint8List?> _legacyGenerate(Page page) async {
  const w = 150.0, h = 200.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, w, h),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final scale = math.min(w / page.size.width, h / page.size.height);
  canvas.scale(scale);
  for (final layer in page.layers) {
    for (final stroke in layer.strokes) {
      if (stroke.points.length < 2) continue;
      final path = ui.Path()
        ..moveTo(stroke.points.first.x, stroke.points.first.y);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = ui.Color(stroke.style.color)
          ..strokeWidth = stroke.style.thickness
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round
          ..style = ui.PaintingStyle.stroke,
      );
    }
  }
  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}

Future<String> _time(String label, Future<Uint8List?> Function() run) async {
  expect(await run(), isNotNull); // warm-up (shader/pipeline setup)
  final ms = <double>[];
  for (var i = 0; i < _runs; i++) {
    final sw = Stopwatch()..start();
    await run();
    ms.add(sw.elapsedMicroseconds / 1000.0);
  }
  ms.sort();
  return '$label median ${ms[ms.length ~/ 2].toStringAsFixed(1)} ms, '
      'worst ${ms.last.toStringAsFixed(1)} ms';
}

void main() {
  testWidgets('thumbnail of the 1,000-stroke page', (tester) async {
    await tester.runAsync(() async {
      final page = _benchmarkPage();
      final legacy = await _time('legacy', () => _legacyGenerate(page));
      final current =
          await _time('painters', () => ThumbnailGenerator.generate(page));
      debugPrint('thumbnail 1,000 strokes: $current | $legacy (n=$_runs)');
    });
  });
}
