import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('EraserTool', () {
    late EraserTool eraserTool;

    setUp(() {
      eraserTool = EraserTool(eraserSize: 20.0);
    });

    group('initialization', () {
      test('default mode is stroke', () {
        expect(eraserTool.mode, equals(EraserMode.stroke));
      });

      test('tolerance is half of eraser size', () {
        expect(eraserTool.tolerance, equals(10.0));
      });

      test('custom eraser size', () {
        final customEraser = EraserTool(eraserSize: 40.0);
        expect(customEraser.tolerance, equals(20.0));
      });

      test('custom mode', () {
        final pixelEraser = EraserTool(mode: EraserMode.pixel);
        expect(pixelEraser.mode, equals(EraserMode.pixel));
      });

      test('eraserSize is accessible', () {
        expect(eraserTool.eraserSize, equals(20.0));
      });
    });

    group('findStrokesToErase', () {
      test('finds stroke at point', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        final result = eraserTool.findStrokesToErase([stroke], 50, 50);
        expect(result.length, equals(1));
        expect(result.first, equals(stroke));
      });

      test('returns empty list when no stroke at point', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        final result = eraserTool.findStrokesToErase([stroke], 50, 200);
        expect(result, isEmpty);
      });

      test('finds topmost stroke when overlapping', () {
        final stroke1 = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        final stroke2 = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 50, y: 0))
            .addPoint(DrawingPoint(x: 50, y: 100));

        final result =
            eraserTool.findStrokesToErase([stroke1, stroke2], 50, 50);
        expect(result.length, equals(1));
        expect(result.first, equals(stroke2)); // Son eklenen (en üstte)
      });

      test('handles empty stroke list', () {
        final result = eraserTool.findStrokesToErase([], 50, 50);
        expect(result, isEmpty);
      });

      test('respects eraser size tolerance', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        // tolerance = 10 (eraserSize/2), thickness/2 = 1
        // effective = 11, point at y=60 is 10 away = should hit
        expect(eraserTool.findStrokesToErase([stroke], 50, 60), hasLength(1));

        // point at y=70 is 20 away > 11 = should miss
        expect(eraserTool.findStrokesToErase([stroke], 50, 70), isEmpty);
      });
    });

    group('erasing session', () {
      test('startErasing clears previous session', () {
        eraserTool.markAsErased('stroke1');
        eraserTool.startErasing();
        expect(eraserTool.erasedCount, equals(0));
      });

      test('markAsErased tracks stroke IDs', () {
        eraserTool.startErasing();
        eraserTool.markAsErased('stroke1');
        eraserTool.markAsErased('stroke2');
        expect(eraserTool.erasedCount, equals(2));
      });

      test('isAlreadyErased prevents double-erase', () {
        eraserTool.startErasing();
        eraserTool.markAsErased('stroke1');

        expect(eraserTool.isAlreadyErased('stroke1'), isTrue);
        expect(eraserTool.isAlreadyErased('stroke2'), isFalse);
      });

      test('endErasing returns erased IDs and clears', () {
        eraserTool.startErasing();
        eraserTool.markAsErased('stroke1');
        eraserTool.markAsErased('stroke2');

        final result = eraserTool.endErasing();

        expect(result, containsAll(['stroke1', 'stroke2']));
        expect(eraserTool.erasedCount, equals(0));
      });

      test('duplicate markAsErased is ignored (Set behavior)', () {
        eraserTool.startErasing();
        eraserTool.markAsErased('stroke1');
        eraserTool.markAsErased('stroke1');
        eraserTool.markAsErased('stroke1');

        expect(eraserTool.erasedCount, equals(1));
      });

      test('multiple sessions are independent', () {
        // Session 1
        eraserTool.startErasing();
        eraserTool.markAsErased('stroke1');
        final result1 = eraserTool.endErasing();

        // Session 2
        eraserTool.startErasing();
        eraserTool.markAsErased('stroke2');
        final result2 = eraserTool.endErasing();

        expect(result1, contains('stroke1'));
        expect(result1, isNot(contains('stroke2')));
        expect(result2, contains('stroke2'));
        expect(result2, isNot(contains('stroke1')));
      });
    });

    group('hasErasedStrokes', () {
      test('false initially after startErasing', () {
        eraserTool.startErasing();
        expect(eraserTool.hasErasedStrokes, isFalse);
      });

      test('true after marking stroke', () {
        eraserTool.startErasing();
        eraserTool.markAsErased('stroke1');
        expect(eraserTool.hasErasedStrokes, isTrue);
      });

      test('false after endErasing', () {
        eraserTool.startErasing();
        eraserTool.markAsErased('stroke1');
        eraserTool.endErasing();
        expect(eraserTool.hasErasedStrokes, isFalse);
      });
    });

    group('pixel mode', () {
      test('pixel mode works same as stroke mode for now', () {
        final pixelEraser = EraserTool(mode: EraserMode.pixel, eraserSize: 20.0);

        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        final result = pixelEraser.findStrokesToErase([stroke], 50, 50);
        expect(result.length, equals(1));
      });
    });

    group('createStroke', () {
      test('createStroke returns empty stroke', () {
        final stroke = eraserTool.createStroke(
          [DrawingPoint(x: 0, y: 0)],
          StrokeStyle.eraser(),
        );

        expect(stroke.isEmpty, isTrue);
      });
    });

    group('inherited DrawingTool behavior', () {
      test('style is eraser style', () {
        expect(eraserTool.style.isEraser, isTrue);
      });

      test('style thickness matches eraserSize', () {
        expect(eraserTool.style.thickness, equals(20.0));
      });
    });
  });
}
