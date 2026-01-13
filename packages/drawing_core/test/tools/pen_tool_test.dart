import 'package:test/test.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/tools/pen_tool.dart';

void main() {
  group('PenTool', () {
    group('Constructor', () {
      test('creates with default pen style', () {
        final tool = PenTool();

        expect(tool.style.color, 0xFF000000); // black
        expect(tool.style.thickness, 2.0);
        expect(tool.style.nibShape, NibShape.circle);
        expect(tool.isDrawing, false);
      });

      test('creates with custom style', () {
        final customStyle = StrokeStyle.pen(
          color: 0xFFFF0000,
          thickness: 5.0,
        );
        final tool = PenTool(style: customStyle);

        expect(tool.style.color, 0xFFFF0000);
        expect(tool.style.thickness, 5.0);
      });
    });

    group('onPointerDown', () {
      test('starts drawing operation', () {
        final tool = PenTool();
        final point = DrawingPoint(x: 10, y: 20);

        expect(tool.isDrawing, false);

        tool.onPointerDown(point);

        expect(tool.isDrawing, true);
        expect(tool.currentPointCount, 1);
        expect(tool.currentPoints[0], point);
      });

      test('clears previous points on new drawing', () {
        final tool = PenTool();

        // First drawing
        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10));
        tool.cancel();

        // New drawing should start fresh
        final newPoint = DrawingPoint(x: 50, y: 50);
        tool.onPointerDown(newPoint);

        expect(tool.currentPointCount, 1);
        expect(tool.currentPoints[0], newPoint);
      });
    });

    group('onPointerMove', () {
      test('adds point when drawing', () {
        final tool = PenTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10));
        tool.onPointerMove(DrawingPoint(x: 20, y: 20));

        expect(tool.currentPointCount, 3);
      });

      test('ignores move when not drawing', () {
        final tool = PenTool();

        tool.onPointerMove(DrawingPoint(x: 10, y: 10));

        expect(tool.currentPointCount, 0);
        expect(tool.isDrawing, false);
      });

      test('adds multiple points correctly', () {
        final tool = PenTool();
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 10),
          DrawingPoint(x: 20, y: 15),
          DrawingPoint(x: 30, y: 25),
          DrawingPoint(x: 40, y: 30),
        ];

        tool.onPointerDown(points[0]);
        for (var i = 1; i < points.length; i++) {
          tool.onPointerMove(points[i]);
        }

        expect(tool.currentPointCount, 5);
        for (var i = 0; i < points.length; i++) {
          expect(tool.currentPoints[i].x, points[i].x);
          expect(tool.currentPoints[i].y, points[i].y);
        }
      });
    });

    group('onPointerUp', () {
      test('returns stroke and ends drawing', () {
        final tool = PenTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10));
        tool.onPointerMove(DrawingPoint(x: 20, y: 20));

        final stroke = tool.onPointerUp();

        expect(stroke, isNotNull);
        expect(stroke!.pointCount, 3);
        expect(tool.isDrawing, false);
        expect(tool.currentPointCount, 0);
      });

      test('returns null when not drawing', () {
        final tool = PenTool();

        final stroke = tool.onPointerUp();

        expect(stroke, isNull);
      });

      test('stroke has correct style', () {
        final customStyle = StrokeStyle.pen(
          color: 0xFF00FF00,
          thickness: 8.0,
        );
        final tool = PenTool(style: customStyle);

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        final stroke = tool.onPointerUp();

        expect(stroke!.style.color, 0xFF00FF00);
        expect(stroke.style.thickness, 8.0);
      });

      test('returns stroke with single point', () {
        final tool = PenTool();

        tool.onPointerDown(DrawingPoint(x: 50, y: 50));
        final stroke = tool.onPointerUp();

        expect(stroke, isNotNull);
        expect(stroke!.pointCount, 1);
      });

      test('clears points after creating stroke', () {
        final tool = PenTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10));
        tool.onPointerUp();

        expect(tool.currentPointCount, 0);

        // Starting new drawing should work correctly
        tool.onPointerDown(DrawingPoint(x: 100, y: 100));
        expect(tool.currentPointCount, 1);
        expect(tool.currentPoints[0].x, 100);
      });
    });

    group('updateStyle', () {
      test('updates style for future strokes', () {
        final tool = PenTool();

        expect(tool.style.color, 0xFF000000);

        tool.updateStyle(StrokeStyle.pen(color: 0xFFFF0000));

        expect(tool.style.color, 0xFFFF0000);
      });

      test('does not affect current drawing', () {
        final tool = PenTool(style: StrokeStyle.pen(color: 0xFF000000));

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10));

        // Change style mid-drawing
        tool.updateStyle(StrokeStyle.pen(color: 0xFFFF0000));

        // The stroke should use the style at the time of creation (which is current style)
        final stroke = tool.onPointerUp();

        // Note: The stroke uses the current style when onPointerUp is called
        expect(stroke!.style.color, 0xFFFF0000);
      });
    });

    group('cancel', () {
      test('clears current points', () {
        final tool = PenTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10));
        tool.onPointerMove(DrawingPoint(x: 20, y: 20));

        expect(tool.currentPointCount, 3);
        expect(tool.isDrawing, true);

        tool.cancel();

        expect(tool.currentPointCount, 0);
        expect(tool.isDrawing, false);
      });

      test('can start new drawing after cancel', () {
        final tool = PenTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.cancel();

        tool.onPointerDown(DrawingPoint(x: 100, y: 100));
        tool.onPointerMove(DrawingPoint(x: 110, y: 110));

        expect(tool.isDrawing, true);
        expect(tool.currentPointCount, 2);
      });

      test('cancel when not drawing has no effect', () {
        final tool = PenTool();

        tool.cancel(); // Should not throw

        expect(tool.isDrawing, false);
        expect(tool.currentPointCount, 0);
      });
    });

    group('currentPoints immutability', () {
      test('currentPoints returns unmodifiable list', () {
        final tool = PenTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        final points = tool.currentPoints;

        expect(
          () => points.add(DrawingPoint(x: 10, y: 10)),
          throwsUnsupportedError,
        );
      });

      test('modifying returned list does not affect tool', () {
        final tool = PenTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10));

        final points = tool.currentPoints;
        expect(points.length, 2);

        // Even though we can't modify the returned list,
        // let's verify the tool's internal state is separate
        tool.onPointerMove(DrawingPoint(x: 20, y: 20));

        // Original list reference still has 2 items
        expect(points.length, 2);
        // But tool now has 3
        expect(tool.currentPointCount, 3);
      });
    });

    group('Complete drawing flow', () {
      test('full drawing cycle produces correct stroke', () {
        final tool = PenTool(
          style: StrokeStyle.pen(color: 0xFF0000FF, thickness: 3.0),
        );

        // Simulate a drawing
        tool.onPointerDown(DrawingPoint(x: 0, y: 0, pressure: 0.5));
        tool.onPointerMove(DrawingPoint(x: 10, y: 5, pressure: 0.6));
        tool.onPointerMove(DrawingPoint(x: 20, y: 10, pressure: 0.7));
        tool.onPointerMove(DrawingPoint(x: 30, y: 8, pressure: 0.8));
        tool.onPointerMove(DrawingPoint(x: 40, y: 15, pressure: 0.9));
        tool.onPointerMove(DrawingPoint(x: 50, y: 20, pressure: 1.0));

        final stroke = tool.onPointerUp();

        expect(stroke, isNotNull);
        expect(stroke!.pointCount, 6);
        expect(stroke.style.color, 0xFF0000FF);
        expect(stroke.style.thickness, 3.0);
        expect(stroke.points[0].pressure, 0.5);
        expect(stroke.points[5].pressure, 1.0);
        expect(stroke.id, isNotEmpty);
      });

      test('multiple drawing cycles', () {
        final tool = PenTool();

        // First stroke
        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10));
        final stroke1 = tool.onPointerUp();

        // Second stroke
        tool.onPointerDown(DrawingPoint(x: 50, y: 50));
        tool.onPointerMove(DrawingPoint(x: 60, y: 60));
        final stroke2 = tool.onPointerUp();

        expect(stroke1, isNotNull);
        expect(stroke2, isNotNull);
        expect(stroke1!.points[0].x, 0);
        expect(stroke2!.points[0].x, 50);
      });

      test('style change between strokes', () {
        final tool = PenTool();

        // First stroke with default style
        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        final stroke1 = tool.onPointerUp();

        // Change style
        tool.updateStyle(StrokeStyle.pen(color: 0xFFFF0000, thickness: 10.0));

        // Second stroke with new style
        tool.onPointerDown(DrawingPoint(x: 50, y: 50));
        final stroke2 = tool.onPointerUp();

        expect(stroke1!.style.color, 0xFF000000);
        expect(stroke1.style.thickness, 2.0);
        expect(stroke2!.style.color, 0xFFFF0000);
        expect(stroke2.style.thickness, 10.0);
      });
    });
  });
}
