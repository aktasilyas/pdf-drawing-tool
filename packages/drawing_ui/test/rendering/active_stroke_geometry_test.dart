import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

List<DrawingPoint> _wave(int n) => [
      for (var i = 0; i < n; i++)
        DrawingPoint(
          x: 20 + i * 2.0,
          y: 100 + 30 * (i % 40 < 20 ? (i % 20) / 20 : 1 - (i % 20) / 20),
          pressure: 0.3 + 0.6 * ((i % 50) / 50),
        ),
    ];

void main() {
  group('ActiveStrokeGeometry mode selection', () {
    test('pressure-sensitive pens use the outline mode', () {
      final g = ActiveStrokeGeometry()..begin(StrokeStyle.brush());
      expect(g.mode, ActiveStrokeMode.outline);
    });

    test('solid pens use the stroked mode', () {
      final g = ActiveStrokeGeometry()..begin(StrokeStyle.pen());
      expect(g.mode, ActiveStrokeMode.stroked);
    });

    test('non-incremental input falls back', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.pen(), incremental: false);
      expect(g.mode, ActiveStrokeMode.fallback);
    });
  });

  group('ActiveStrokeGeometry sync', () {
    for (final style in [StrokeStyle.pen(), StrokeStyle.brush()]) {
      test('consumes only new points and bumps version (${style.thickness})',
          () {
        final points = _wave(300);
        final g = ActiveStrokeGeometry()..begin(style);
        var version = g.version;
        for (var n = 1; n <= points.length; n++) {
          g.sync(points.sublist(0, n));
          expect(g.consumed, n);
          expect(g.version, greaterThan(version));
          version = g.version;
        }
      });

      test('paints without throwing for 1, 2 and many points', () {
        for (final n in [1, 2, 3, 120]) {
          final g = ActiveStrokeGeometry()
            ..begin(style)
            ..sync(_wave(n));
          final recorder = ui.PictureRecorder();
          g.paint(ui.Canvas(recorder));
          recorder.endRecording().dispose();
        }
      });
    }

    test('translucent highlighter paints inside a layer', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.highlighter())
        ..sync(_wave(50));
      final recorder = ui.PictureRecorder();
      g.paint(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    });

    test('clear stops painting', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.pen())
        ..sync(_wave(10))
        ..clear();
      expect(g.consumed, 0);
    });
  });

  group('ActiveStrokeGeometry stroked chunks', () {
    const chunk = ActiveStrokeGeometry.strokedChunk;

    test('live body stays bounded while chunks freeze', () {
      final points = _wave(1000);
      final g = ActiveStrokeGeometry()..begin(StrokeStyle.pen());
      for (var n = 1; n <= points.length; n++) {
        g.sync(points.sublist(0, n));
        expect(g.liveSegments, lessThan(chunk));
      }
      // n points give n - 2 quadratic segments.
      expect(g.frozenChunks, (points.length - 2) ~/ chunk);
      expect(g.liveSegments, (points.length - 2) % chunk);
      g.dispose();
    });

    test('begin, clear and dispose drop frozen chunks', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.pen())
        ..sync(_wave(200));
      expect(g.frozenChunks, greaterThan(0));
      g.begin(StrokeStyle.pen());
      expect(g.frozenChunks, 0);
      g.sync(_wave(200));
      g.clear();
      expect(g.frozenChunks, 0);
      g
        ..begin(StrokeStyle.pen())
        ..sync(_wave(200))
        ..dispose();
      expect(g.frozenChunks, 0);
    });

    test('a shrinking point list after freezes rebuilds from scratch', () {
      final points = _wave(300);
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.pen())
        ..sync(points);
      expect(g.frozenChunks, (300 - 2) ~/ chunk);
      g.sync(points.sublist(0, 50));
      expect(g.consumed, 50);
      expect(g.frozenChunks, (50 - 2) ~/ chunk);
      expect(g.liveSegments, (50 - 2) % chunk);
      g.dispose();
    });

    test('square-cap styles keep one body path', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle.highlighter())
        ..sync(_wave(300));
      expect(g.mode, ActiveStrokeMode.stroked);
      expect(g.frozenChunks, 0);
      g.dispose();
    });

    for (final entry in {
      'pen': StrokeStyle.pen(thickness: 3),
      'pen (thick)': StrokeStyle.pen(thickness: 12),
    }.entries) {
      for (final input in {'sine': _sine(400), 'zigzag': _wave(400)}.entries) {
        test('chunked live render matches committed render: '
            '${entry.key}, ${input.key}', () async {
          final points = input.value;
          final g = ActiveStrokeGeometry()..begin(entry.value);
          for (var n = 1; n <= points.length; n++) {
            g.sync(points.sublist(0, n));
          }
          expect(g.frozenChunks, greaterThan(5));
          final live = await _raster(g.paint);
          final committed = await _raster((c) => FlutterStrokeRenderer()
              .renderActiveStroke(c, points, entry.value));
          expect(_diffRatio(live, committed), lessThan(0.005));
          g.dispose();
        });
      }
    }
  });
}

List<DrawingPoint> _sine(int n) => [
      for (var i = 0; i < n; i++)
        DrawingPoint(
          x: 20 + i * 0.9,
          y: 120 + 70 * math.sin(i / 25),
          pressure: 0.5,
        ),
    ];

Future<Uint8List> _raster(void Function(ui.Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 400, 240),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 240);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

double _diffRatio(Uint8List a, Uint8List b) {
  var bad = 0;
  for (var i = 0; i < a.length; i += 4) {
    var d = 0;
    for (var c = 0; c < 4; c++) {
      final delta = (a[i + c] - b[i + c]).abs();
      if (delta > d) d = delta;
    }
    if (d > 8) bad++;
  }
  return bad / (a.length / 4);
}
