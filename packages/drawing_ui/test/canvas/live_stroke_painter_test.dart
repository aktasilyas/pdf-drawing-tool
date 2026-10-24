import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/canvas.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _w = 400, _h = 240;

List<DrawingPoint> _input() => [
      for (var i = 0; i < 160; i++)
        DrawingPoint(
          x: 20 + i * 2.2,
          y: 120 + 60 * _tri(i / 40),
          pressure: 0.3 + 0.6 * ((i % 50) / 50),
        ),
    ];

double _tri(double t) {
  final f = t - t.floorToDouble();
  return f < 0.5 ? f * 4 - 1 : 3 - f * 4;
}

Future<Uint8List> _raster(void Function(ui.Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 400, 240),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_w, _h);
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
      d = (a[i + c] - b[i + c]).abs() > d ? (a[i + c] - b[i + c]).abs() : d;
    }
    if (d > 8) bad++;
  }
  return bad / (a.length / 4);
}

void main() {
  _prefixAndTransitionTests();
  final styles = <String, StrokeStyle>{
    'pen': StrokeStyle.pen(thickness: 3),
    'highlighter': StrokeStyle.highlighter(),
    'brush (pressure)': StrokeStyle.brush(),
  };

  for (final entry in styles.entries) {
    test('live render matches committed render: ${entry.key}', () async {
      final controller = DrawingController();
      final input = _input();
      controller.startStroke(input.first, entry.value);
      for (final p in input.skip(1)) {
        controller.addPoint(p);
      }
      final points = controller.activePoints;

      final live = await _raster(controller.geometry.paint);
      final committed = await _raster((c) =>
          FlutterStrokeRenderer().renderActiveStroke(c, points, entry.value));

      expect(_diffRatio(live, committed), lessThan(0.005));
      controller.dispose();
    });
  }

  test('LiveStrokePainter repaints through the listenable only', () {
    final controller = DrawingController();
    final a =
        LiveStrokePainter(geometry: controller.geometry, repaint: controller);
    final b =
        LiveStrokePainter(geometry: controller.geometry, repaint: controller);
    expect(b.shouldRepaint(a), isFalse);
    final c = LiveStrokePainter(
        geometry: ActiveStrokeGeometry(), repaint: controller);
    expect(c.shouldRepaint(a), isTrue);
    controller.dispose();
  });
}

void _prefixAndTransitionTests() {
  test('every early prefix of a brush stroke matches the legacy render',
      () async {
    final style = StrokeStyle.brush();
    final input = _input();
    final controller = DrawingController();
    controller.startStroke(input.first, style);
    for (var n = 1; n <= 70; n++) {
      if (n > 1) controller.addPoint(input[n - 1]);
      final points = controller.activePoints;
      final live = await _raster(controller.geometry.paint);
      final legacy = await _raster(
          (c) => FlutterStrokeRenderer().renderActiveStroke(c, points, style));
      expect(_diffRatio(live, legacy), lessThan(0.005), reason: 'n=$n');
    }
    controller.dispose();
  });

  group('DrawingController geometry transitions', () {
    test('startStroke / endStroke / cancel / reset', () {
      final c = DrawingController();
      final input = _input();
      c.startStroke(input.first, StrokeStyle.pen());
      expect(c.geometry.mode, ActiveStrokeMode.stroked);
      expect(c.geometry.consumed, 1);
      for (final p in input.skip(1).take(9)) {
        c.addPoint(p);
      }
      expect(c.geometry.consumed, c.pointCount);
      c.endStroke();
      expect(c.geometry.consumed, 0);
      c.startStroke(input.first, StrokeStyle.pen());
      c.cancelStroke();
      expect(c.geometry.consumed, 0);
      c.startStroke(input.first, StrokeStyle.pen());
      c.reset();
      expect(c.geometry.consumed, 0);
      c.dispose();
    });

    test('updateStyle mid-stroke rebuilds in the new mode', () {
      final c = DrawingController();
      final input = _input();
      c.startStroke(input.first, StrokeStyle.pen());
      for (final p in input.skip(1).take(30)) {
        c.addPoint(p);
      }
      c.updateStyle(StrokeStyle.brush());
      expect(c.geometry.mode, ActiveStrokeMode.outline);
      expect(c.geometry.consumed, c.pointCount);
      c.dispose();
    });

    test('no filter and straight line use the fallback', () {
      final off = DrawingController(inputFilter: null);
      off.startStroke(_input().first, StrokeStyle.pen());
      expect(off.geometry.mode, ActiveStrokeMode.fallback);
      final line = DrawingController();
      line.startStroke(_input().first, StrokeStyle.pen(), straightLine: true);
      expect(line.geometry.mode, ActiveStrokeMode.fallback);
      off.dispose();
      line.dispose();
    });

    test('sync rebuilds when the point list shrinks', () {
      final g = ActiveStrokeGeometry()..begin(StrokeStyle.pen());
      final pts = _input();
      g.sync(pts.take(20).toList());
      g.sync(pts.take(5).toList());
      expect(g.consumed, 5);
    });
  });
}
