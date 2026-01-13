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
  });
}
