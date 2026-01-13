import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';

void main() {
  group('CommittedStrokesPainter', () {
    late FlutterStrokeRenderer renderer;

    setUp(() {
      renderer = FlutterStrokeRenderer();
    });

    test('should not throw for empty stroke list', () {
      final painter = CommittedStrokesPainter(
        strokes: [],
        renderer: renderer,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('should render single stroke', () {
      final stroke = Stroke.create(
        points: [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 100, y: 100),
        ],
        style: StrokeStyle.pen(),
      );

      final painter = CommittedStrokesPainter(
        strokes: [stroke],
        renderer: renderer,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('should render multiple strokes', () {
      final strokes = [
        Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(),
        ),
        Stroke.create(
          points: [
            DrawingPoint(x: 200, y: 0),
            DrawingPoint(x: 300, y: 100),
          ],
          style: StrokeStyle.highlighter(),
        ),
      ];

      final painter = CommittedStrokesPainter(
        strokes: strokes,
        renderer: renderer,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    group('shouldRepaint', () {
      test('should return false for same stroke count and points', () {
        final strokes = [
          Stroke.create(
            points: [
              DrawingPoint(x: 0, y: 0),
              DrawingPoint(x: 100, y: 100),
            ],
            style: StrokeStyle.pen(),
          ),
        ];

        final oldPainter = CommittedStrokesPainter(
          strokes: strokes,
          renderer: renderer,
        );

        final newPainter = CommittedStrokesPainter(
          strokes: strokes,
          renderer: renderer,
        );

        expect(newPainter.shouldRepaint(oldPainter), isFalse);
      });

      test('should return true when stroke count changes', () {
        final stroke1 = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(),
        );

        final stroke2 = Stroke.create(
          points: [
            DrawingPoint(x: 200, y: 0),
            DrawingPoint(x: 300, y: 100),
          ],
          style: StrokeStyle.pen(),
        );

        final oldPainter = CommittedStrokesPainter(
          strokes: [stroke1],
          renderer: renderer,
        );

        final newPainter = CommittedStrokesPainter(
          strokes: [stroke1, stroke2],
          renderer: renderer,
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should return true when total point count changes', () {
        final stroke1 = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(),
        );

        final stroke1Extended = Stroke.create(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 50, y: 50),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle.pen(),
        );

        final oldPainter = CommittedStrokesPainter(
          strokes: [stroke1],
          renderer: renderer,
        );

        final newPainter = CommittedStrokesPainter(
          strokes: [stroke1Extended],
          renderer: renderer,
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should return false for empty lists', () {
        final oldPainter = CommittedStrokesPainter(
          strokes: [],
          renderer: renderer,
        );

        final newPainter = CommittedStrokesPainter(
          strokes: [],
          renderer: renderer,
        );

        expect(newPainter.shouldRepaint(oldPainter), isFalse);
      });
    });
  });

  group('ActiveStrokePainter', () {
    late FlutterStrokeRenderer renderer;

    setUp(() {
      renderer = FlutterStrokeRenderer();
    });

    test('should not throw for empty points', () {
      final painter = ActiveStrokePainter(
        points: [],
        style: StrokeStyle.pen(),
        renderer: renderer,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('should render active stroke', () {
      final points = [
        DrawingPoint(x: 0, y: 0),
        DrawingPoint(x: 50, y: 50),
        DrawingPoint(x: 100, y: 100),
      ];

      final painter = ActiveStrokePainter(
        points: points,
        style: StrokeStyle.pen(),
        renderer: renderer,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    group('shouldRepaint', () {
      test('should return false for same point count and style', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 100, y: 100),
        ];
        final style = StrokeStyle.pen();

        final oldPainter = ActiveStrokePainter(
          points: points,
          style: style,
          renderer: renderer,
        );

        final newPainter = ActiveStrokePainter(
          points: points,
          style: style,
          renderer: renderer,
        );

        expect(newPainter.shouldRepaint(oldPainter), isFalse);
      });

      test('should return true when point count changes', () {
        final style = StrokeStyle.pen();

        final oldPainter = ActiveStrokePainter(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: style,
          renderer: renderer,
        );

        final newPainter = ActiveStrokePainter(
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 50, y: 50),
            DrawingPoint(x: 100, y: 100),
          ],
          style: style,
          renderer: renderer,
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should return true when style changes', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 100, y: 100),
        ];

        final oldPainter = ActiveStrokePainter(
          points: points,
          style: StrokeStyle.pen(),
          renderer: renderer,
        );

        final newPainter = ActiveStrokePainter(
          points: points,
          style: StrokeStyle.highlighter(),
          renderer: renderer,
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should return false for empty points', () {
        final style = StrokeStyle.pen();

        final oldPainter = ActiveStrokePainter(
          points: [],
          style: style,
          renderer: renderer,
        );

        final newPainter = ActiveStrokePainter(
          points: [],
          style: style,
          renderer: renderer,
        );

        expect(newPainter.shouldRepaint(oldPainter), isFalse);
      });
    });
  });

  group('DrawingController', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with default values', () {
      expect(controller.isDrawing, isFalse);
      expect(controller.activePoints, isEmpty);
      expect(controller.pointCount, equals(0));
      expect(controller.activeStyle, equals(StrokeStyle.pen()));
    });

    group('startStroke', () {
      test('should set isDrawing to true', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );

        expect(controller.isDrawing, isTrue);
      });

      test('should add initial point', () {
        controller.startStroke(
          DrawingPoint(x: 100, y: 200),
          StrokeStyle.pen(),
        );

        expect(controller.pointCount, equals(1));
        expect(controller.activePoints.first.x, equals(100));
        expect(controller.activePoints.first.y, equals(200));
      });

      test('should set style', () {
        final style = StrokeStyle.highlighter();
        controller.startStroke(DrawingPoint(x: 0, y: 0), style);

        expect(controller.activeStyle, equals(style));
      });

      test('should clear previous points', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );
        controller.addPoint(DrawingPoint(x: 50, y: 50));
        controller.addPoint(DrawingPoint(x: 100, y: 100));

        expect(controller.pointCount, equals(3));

        // Start new stroke
        controller.startStroke(
          DrawingPoint(x: 200, y: 200),
          StrokeStyle.pen(),
        );

        expect(controller.pointCount, equals(1));
      });
    });

    group('addPoint', () {
      test('should add point when drawing', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );
        controller.addPoint(DrawingPoint(x: 50, y: 50));
        controller.addPoint(DrawingPoint(x: 100, y: 100));

        expect(controller.pointCount, equals(3));
      });

      test('should not add point when not drawing', () {
        controller.addPoint(DrawingPoint(x: 50, y: 50));

        expect(controller.pointCount, equals(0));
        expect(controller.isDrawing, isFalse);
      });
    });

    group('endStroke', () {
      test('should return Stroke with all points', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );
        controller.addPoint(DrawingPoint(x: 50, y: 50));
        controller.addPoint(DrawingPoint(x: 100, y: 100));

        final stroke = controller.endStroke();

        expect(stroke, isNotNull);
        expect(stroke!.pointCount, equals(3));
      });

      test('should clear points after ending', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );
        controller.addPoint(DrawingPoint(x: 100, y: 100));

        controller.endStroke();

        expect(controller.pointCount, equals(0));
        expect(controller.isDrawing, isFalse);
      });

      test('should return null when not drawing', () {
        final stroke = controller.endStroke();

        expect(stroke, isNull);
      });

      test('should return null for empty points', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );
        // Clear points manually via cancel then check
        controller.cancelStroke();

        final stroke = controller.endStroke();
        expect(stroke, isNull);
      });

      test('should use correct style in stroke', () {
        final style = StrokeStyle.brush();
        controller.startStroke(DrawingPoint(x: 0, y: 0), style);
        controller.addPoint(DrawingPoint(x: 100, y: 100));

        final stroke = controller.endStroke();

        expect(stroke!.style, equals(style));
      });
    });

    group('cancelStroke', () {
      test('should clear points', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );
        controller.addPoint(DrawingPoint(x: 100, y: 100));

        controller.cancelStroke();

        expect(controller.pointCount, equals(0));
      });

      test('should set isDrawing to false', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );

        controller.cancelStroke();

        expect(controller.isDrawing, isFalse);
      });
    });

    group('updateStyle', () {
      test('should update active style', () {
        final newStyle = StrokeStyle.eraser();
        controller.updateStyle(newStyle);

        expect(controller.activeStyle, equals(newStyle));
      });
    });

    group('reset', () {
      test('should clear all state', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.highlighter(),
        );
        controller.addPoint(DrawingPoint(x: 100, y: 100));

        controller.reset();

        expect(controller.isDrawing, isFalse);
        expect(controller.pointCount, equals(0));
        expect(controller.activeStyle, equals(StrokeStyle.pen()));
      });
    });

    group('notifications', () {
      test('should notify on startStroke', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );

        expect(notified, isTrue);
      });

      test('should notify on addPoint', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );

        var notified = false;
        controller.addListener(() => notified = true);

        controller.addPoint(DrawingPoint(x: 100, y: 100));

        expect(notified, isTrue);
      });

      test('should notify on endStroke', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );

        var notified = false;
        controller.addListener(() => notified = true);

        controller.endStroke();

        expect(notified, isTrue);
      });

      test('should notify on cancelStroke', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );

        var notified = false;
        controller.addListener(() => notified = true);

        controller.cancelStroke();

        expect(notified, isTrue);
      });

      test('should notify on updateStyle', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.updateStyle(StrokeStyle.brush());

        expect(notified, isTrue);
      });

      test('should notify on reset', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.reset();

        expect(notified, isTrue);
      });
    });

    group('activePoints immutability', () {
      test('should return unmodifiable list', () {
        controller.startStroke(
          DrawingPoint(x: 0, y: 0),
          StrokeStyle.pen(),
        );

        final points = controller.activePoints;

        expect(
          () => points.add(DrawingPoint(x: 100, y: 100)),
          throwsUnsupportedError,
        );
      });
    });
  });
}
