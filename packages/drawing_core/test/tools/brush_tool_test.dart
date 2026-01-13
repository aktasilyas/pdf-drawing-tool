import 'package:test/test.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/tools/brush_tool.dart';

void main() {
  group('BrushTool', () {
    group('Constructor', () {
      test('creates with default brush style', () {
        final tool = BrushTool();

        expect(tool.style.color, 0xFF000000); // black
        expect(tool.style.thickness, 5.0);
        expect(tool.style.opacity, 1.0);
        expect(tool.style.nibShape, NibShape.ellipse);
        expect(tool.isDrawing, false);
      });

      test('creates with custom style', () {
        final customStyle = StrokeStyle.brush(
          color: 0xFFFF0000, // red
          thickness: 10.0,
        );
        final tool = BrushTool(style: customStyle);

        expect(tool.style.color, 0xFFFF0000);
        expect(tool.style.thickness, 10.0);
        expect(tool.style.nibShape, NibShape.ellipse);
      });

      test('nibShape is ellipse for default brush', () {
        final tool = BrushTool();
        expect(tool.style.nibShape, NibShape.ellipse);
      });
    });

    group('Drawing flow', () {
      test('complete drawing cycle produces correct stroke', () {
        final tool = BrushTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0, pressure: 0.3));
        tool.onPointerMove(DrawingPoint(x: 10, y: 5, pressure: 0.5));
        tool.onPointerMove(DrawingPoint(x: 20, y: 10, pressure: 0.7));
        tool.onPointerMove(DrawingPoint(x: 30, y: 8, pressure: 0.9));
        tool.onPointerMove(DrawingPoint(x: 40, y: 15, pressure: 1.0));

        final stroke = tool.onPointerUp();

        expect(stroke, isNotNull);
        expect(stroke!.pointCount, 5);
        expect(stroke.style.color, 0xFF000000);
        expect(stroke.style.nibShape, NibShape.ellipse);
      });

      test('stroke preserves brush style properties', () {
        final tool = BrushTool(
          style: StrokeStyle.brush(color: 0xFF00FF00, thickness: 8.0),
        );

        tool.onPointerDown(DrawingPoint(x: 10, y: 10));
        final stroke = tool.onPointerUp();

        expect(stroke!.style.nibShape, NibShape.ellipse);
        expect(stroke.style.color, 0xFF00FF00);
        expect(stroke.style.thickness, 8.0);
      });
    });

    group('Pressure sensitivity', () {
      test('pressure values are preserved in stroke points', () {
        final tool = BrushTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0, pressure: 0.2));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10, pressure: 0.5));
        tool.onPointerMove(DrawingPoint(x: 20, y: 20, pressure: 0.8));
        tool.onPointerMove(DrawingPoint(x: 30, y: 30, pressure: 1.0));

        final stroke = tool.onPointerUp();

        expect(stroke!.points[0].pressure, 0.2);
        expect(stroke.points[1].pressure, 0.5);
        expect(stroke.points[2].pressure, 0.8);
        expect(stroke.points[3].pressure, 1.0);
      });

      test('varying pressure creates correct stroke data', () {
        final tool = BrushTool();

        // Simulate pressure curve: light start, heavy middle, light end
        final pressureValues = [0.1, 0.3, 0.6, 0.9, 1.0, 0.8, 0.5, 0.2];

        tool.onPointerDown(DrawingPoint(x: 0, y: 0, pressure: pressureValues[0]));
        for (var i = 1; i < pressureValues.length; i++) {
          tool.onPointerMove(
            DrawingPoint(
              x: i * 10.0,
              y: i * 5.0,
              pressure: pressureValues[i],
            ),
          );
        }

        final stroke = tool.onPointerUp();

        expect(stroke!.pointCount, pressureValues.length);
        for (var i = 0; i < pressureValues.length; i++) {
          expect(stroke.points[i].pressure, pressureValues[i]);
        }
      });
    });

    group('Style updates', () {
      test('updateStyle changes future strokes', () {
        final tool = BrushTool();

        tool.updateStyle(StrokeStyle.brush(color: 0xFF0000FF, thickness: 15.0));

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        final stroke = tool.onPointerUp();

        expect(stroke!.style.color, 0xFF0000FF);
        expect(stroke.style.thickness, 15.0);
      });
    });

    group('Multiple strokes', () {
      test('multiple drawing cycles work correctly', () {
        final tool = BrushTool();

        // First stroke
        tool.onPointerDown(DrawingPoint(x: 0, y: 0, pressure: 0.5));
        tool.onPointerMove(DrawingPoint(x: 50, y: 50, pressure: 1.0));
        final stroke1 = tool.onPointerUp();

        // Second stroke
        tool.onPointerDown(DrawingPoint(x: 100, y: 0, pressure: 0.3));
        tool.onPointerMove(DrawingPoint(x: 150, y: 50, pressure: 0.7));
        final stroke2 = tool.onPointerUp();

        expect(stroke1, isNotNull);
        expect(stroke2, isNotNull);
        expect(stroke1!.points[0].x, 0);
        expect(stroke2!.points[0].x, 100);
        expect(stroke1.points[0].pressure, 0.5);
        expect(stroke2.points[0].pressure, 0.3);
      });
    });

    group('Cancel', () {
      test('cancel clears drawing state', () {
        final tool = BrushTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0, pressure: 0.5));
        tool.onPointerMove(DrawingPoint(x: 10, y: 10, pressure: 0.7));

        expect(tool.isDrawing, true);
        expect(tool.currentPointCount, 2);

        tool.cancel();

        expect(tool.isDrawing, false);
        expect(tool.currentPointCount, 0);
      });

      test('can draw after cancel', () {
        final tool = BrushTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.cancel();

        tool.onPointerDown(DrawingPoint(x: 100, y: 100, pressure: 0.8));
        tool.onPointerMove(DrawingPoint(x: 110, y: 110, pressure: 0.9));
        final stroke = tool.onPointerUp();

        expect(stroke, isNotNull);
        expect(stroke!.points[0].x, 100);
        expect(stroke.points[0].pressure, 0.8);
      });
    });
  });
}
