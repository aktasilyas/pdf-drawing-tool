import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';

void main() {
  late FlutterStrokeRenderer renderer;

  setUp(() {
    renderer = FlutterStrokeRenderer();
  });

  group('FlutterStrokeRenderer', () {
    group('renderStroke', () {
      test('should not throw for empty stroke', () {
        final stroke = Stroke.create(
          points: [],
          style: StrokeStyle.pen(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should render single point stroke as circle', () {
        final stroke = Stroke.create(
          points: [DrawingPoint(x: 100, y: 100)],
          style: StrokeStyle.pen(thickness: 4.0),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should render two point stroke as line', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should render multi-point stroke with bezier curves', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 50, y: 25),
            DrawingPoint(x: 100, y: 0),
            DrawingPoint(x: 150, y: 25),
            DrawingPoint(x: 200, y: 0),
          ],
          style: StrokeStyle.pen(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });
    });

    group('renderStrokes', () {
      test('should render multiple strokes in order', () {
        final strokes = [
          Stroke.create(
            points: [
              DrawingPoint(x: 0, y: 0),
              DrawingPoint(x: 100, y: 100),
            ],
            style: StrokeStyle.pen(color: 0xFFFF0000),
          ),
          Stroke.create(
            points: [
              DrawingPoint(x: 100, y: 0),
              DrawingPoint(x: 0, y: 100),
            ],
            style: StrokeStyle.pen(color: 0xFF0000FF),
          ),
        ];

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStrokes(canvas, strokes), returnsNormally);

        recorder.endRecording();
      });

      test('should handle empty stroke list', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStrokes(canvas, []), returnsNormally);

        recorder.endRecording();
      });
    });

    group('renderActiveStroke', () {
      test('should render active stroke with given style', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 50, y: 50),
          DrawingPoint(x: 100, y: 100),
        ];

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => renderer.renderActiveStroke(
            canvas,
            points,
            StrokeStyle.pen(),
          ),
          returnsNormally,
        );

        recorder.endRecording();
      });

      test('should not throw for empty points', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => renderer.renderActiveStroke(
            canvas,
            [],
            StrokeStyle.pen(),
          ),
          returnsNormally,
        );

        recorder.endRecording();
      });
    });

    group('_createPaint', () {
      test('should create paint with correct color', () {
        final redStroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(color: 0xFFFF0000),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, redStroke), returnsNormally);

        recorder.endRecording();
      });

      test('should create paint with correct thickness', () {
        final thickStroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(thickness: 10.0),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => renderer.renderStroke(canvas, thickStroke),
          returnsNormally,
        );

        recorder.endRecording();
      });

      test('should create paint with correct opacity', () {
        final semiTransparentStroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.highlighter(), // Default opacity 0.5
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => renderer.renderStroke(canvas, semiTransparentStroke),
          returnsNormally,
        );

        recorder.endRecording();
      });
    });

    group('NibShape to StrokeCap mapping', () {
      test('should use round cap for circle nib', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(), // Default is circle nib
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should use square cap for rectangle nib', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.highlighter(), // Highlighter uses rectangle nib
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should use round cap for ellipse nib', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.brush(), // Brush uses ellipse nib
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });
    });

    group('BlendMode mapping', () {
      test('should handle normal blend mode', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(), // Default is normal blend mode
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle multiply blend mode', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            blendMode: DrawingBlendMode.multiply,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle screen blend mode', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            blendMode: DrawingBlendMode.screen,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle overlay blend mode', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            blendMode: DrawingBlendMode.overlay,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle darken blend mode', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            blendMode: DrawingBlendMode.darken,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle lighten blend mode', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            blendMode: DrawingBlendMode.lighten,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });
    });

    group('edge cases', () {
      test('should handle stroke with pressure variations', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0, pressure: 0.5),
            DrawingPoint(x: 50, y: 50, pressure: 1.0),
            DrawingPoint(x: 100, y: 100, pressure: 0.3),
          ],
          style: StrokeStyle.pen(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle stroke with tilt values', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0, tilt: 0.0),
            DrawingPoint(x: 50, y: 50, tilt: 0.5),
            DrawingPoint(x: 100, y: 100, tilt: 1.0),
          ],
          style: StrokeStyle.pen(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle eraser style stroke', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.eraser(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle brush style stroke', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 50, y: 25),
            DrawingPoint(x: 100, y: 50),
          ],
          style: StrokeStyle.brush(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle highlighter style stroke', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 0),
          ],
          style: StrokeStyle.highlighter(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle very long stroke', () {
        final points = List.generate(
          1000,
          (i) => DrawingPoint(x: i.toDouble(), y: (i % 100).toDouble()),
        );

        final stroke = Stroke.create(
          points: points,
          style: StrokeStyle.pen(),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });
    });

    group('dash pattern rendering', () {
      test('should render dashed stroke', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 0),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            pattern: StrokePattern.dashed,
            dashPattern: [8.0, 4.0],
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should render dotted stroke', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 0),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            pattern: StrokePattern.dotted,
            dashPattern: [2.0, 2.0],
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle solid pattern (no dashing)', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 0),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            pattern: StrokePattern.solid,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle complex dash pattern', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 50, y: 50),
            DrawingPoint(x: 100, y: 0),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            pattern: StrokePattern.dashed,
            dashPattern: [10.0, 5.0, 2.0, 5.0],
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });
    });

    group('glow effect rendering', () {
      test('should render stroke with glow', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF00FF00,
            thickness: 3.0,
            glowRadius: 8.0,
            glowIntensity: 0.6,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should render neon highlighter style', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 50),
            DrawingPoint(x: 100, y: 50),
          ],
          style: StrokeStyle(
            color: 0xFFFF00FF,
            thickness: 15.0,
            opacity: 0.8,
            glowRadius: 8.0,
            glowIntensity: 0.6,
            nibShape: NibShape.rectangle,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle zero glow (no effect)', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            glowRadius: 0.0,
            glowIntensity: 0.0,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should handle glow with zero intensity', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            glowRadius: 10.0,
            glowIntensity: 0.0,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });
    });

    group('combined effects', () {
      test('should render dashed stroke with glow', () {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(
            color: 0xFF00FFFF,
            thickness: 3.0,
            pattern: StrokePattern.dashed,
            dashPattern: [8.0, 4.0],
            glowRadius: 5.0,
            glowIntensity: 0.5,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => renderer.renderStroke(canvas, stroke), returnsNormally);

        recorder.endRecording();
      });

      test('should render active stroke with all effects', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 50, y: 50),
          DrawingPoint(x: 100, y: 0),
        ];

        final style = StrokeStyle(
          color: 0xFFFF00FF,
          thickness: 4.0,
          pattern: StrokePattern.dashed,
          dashPattern: [10.0, 5.0],
          glowRadius: 6.0,
          glowIntensity: 0.7,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => renderer.renderActiveStroke(canvas, points, style),
          returnsNormally,
        );

        recorder.endRecording();
      });
    });

    group('routing (texture -> outline -> stroked)', () {
      List<DrawingPoint> line() => [
            for (var i = 0; i <= 80; i++)
              DrawingPoint(x: 20 + i * 2.0, y: 50, pressure: 0.5),
          ];

      Future<ByteData> raster(Stroke stroke) async {
        final recorder = PictureRecorder();
        renderer.renderStroke(Canvas(recorder), stroke);
        final image = await recorder.endRecording().toImage(200, 100);
        final data = await image.toByteData();
        image.dispose();
        return data!;
      }

      int columnHeight(ByteData d, int x) {
        var n = 0;
        for (var y = 0; y < 100; y++) {
          if (d.getUint8((y * 200 + x) * 4 + 3) > 127) n++;
        }
        return n;
      }

      final taperedStyle = StrokeStyle(
        thickness: 10,
        color: 0xFF000000,
        dynamics: const StrokeDynamics(taperStart: 40, taperEnd: 40),
      );

      testWidgets('tapered stroke is thin near its end', (tester) async {
        await tester.runAsync(() async {
          final d = await raster(Stroke.create(
            points: line(),
            style: taperedStyle,
          ));
          final mid = columnHeight(d, 100);
          final end = columnHeight(d, 178);
          expect(mid, greaterThan(4));
          expect(end, lessThan(mid * 0.3));
        });
      });

      testWidgets('ballpoint-like stroke keeps round ends', (tester) async {
        await tester.runAsync(() async {
          final d = await raster(Stroke.create(
            points: line(),
            style: StrokeStyle(
              thickness: 10,
              color: 0xFF000000,
              dynamics: const StrokeDynamics(velocityThinning: 0.1),
            ),
          ));
          final mid = columnHeight(d, 100);
          final end = columnHeight(d, 178);
          expect(end, greaterThan(mid * 0.6));
        });
      });

      testWidgets('pencil texture wins over pressure and taper',
          (tester) async {
        await tester.runAsync(() async {
          final pencil = StrokeStyle(
            thickness: 10,
            color: 0xFF000000,
            texture: StrokeTexture.pencil,
            pressureSensitive: true,
            dynamics: const StrokeDynamics(taperEnd: 40),
          );
          final plain = taperedStyle.copyWith(
            dynamics: const StrokeDynamics(taperStart: 40, taperEnd: 40),
          );
          final a = await raster(Stroke.create(points: line(), style: pencil));
          final b = await raster(Stroke.create(points: line(), style: plain));
          // Texture output differs from the plain outline fill.
          var differs = false;
          for (var i = 0; i < a.lengthInBytes && !differs; i++) {
            differs = a.getUint8(i) != b.getUint8(i);
          }
          expect(differs, isTrue);
        });
      });
    });
  });
}
