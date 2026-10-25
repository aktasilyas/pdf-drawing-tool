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

    test('tapered non-pressure style uses the outline mode', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle(
            color: 0xFF000000,
            thickness: 4,
            dynamics: const StrokeDynamics(taperEnd: 8)));
      expect(g.mode, ActiveStrokeMode.outline);
    });

    test('pencil texture wins over pressure (fallback)', () {
      final g = ActiveStrokeGeometry()
        ..begin(StrokeStyle(
            color: 0xFF000000,
            thickness: 4,
            texture: StrokeTexture.pencil,
            pressureSensitive: true));
      expect(g.mode, ActiveStrokeMode.fallback);
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

  group('ActiveStrokeGeometry parity with committed render', () {
    testWidgets('tapered style: live and committed pixels match',
        (tester) async {
      await tester.runAsync(() async {
        final style = StrokeStyle(
          thickness: 8,
          color: 0xFF000000,
          dynamics: const StrokeDynamics(taperStart: 30, taperEnd: 30),
        );
        final points = _wave(120);

        Future<ByteData> raster(void Function(ui.Canvas) draw) async {
          final recorder = ui.PictureRecorder();
          draw(ui.Canvas(recorder));
          final image = await recorder.endRecording().toImage(300, 200);
          final data = await image.toByteData();
          image.dispose();
          return data!;
        }

        final committed = await raster((c) => FlutterStrokeRenderer()
            .renderStroke(c, Stroke.create(points: points, style: style)));
        final geometry = ActiveStrokeGeometry()
          ..begin(style)
          ..sync(points);
        final live = await raster(geometry.paint);

        var diff = 0;
        for (var i = 0; i < committed.lengthInBytes; i++) {
          if ((committed.getUint8(i) - live.getUint8(i)).abs() > 8) diff++;
        }
        expect(diff / committed.lengthInBytes, lessThan(0.005));
      });
    });
  });
}
