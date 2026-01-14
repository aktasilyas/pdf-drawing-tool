import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/shape_type.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/tools/arrow_tool.dart';
import 'package:drawing_core/src/tools/ellipse_tool.dart';
import 'package:drawing_core/src/tools/line_tool.dart';
import 'package:drawing_core/src/tools/rectangle_tool.dart';
import 'package:test/test.dart';

void main() {
  group('ShapeTool', () {
    late LineTool lineTool;
    late RectangleTool rectangleTool;
    late EllipseTool ellipseTool;
    late ArrowTool arrowTool;

    setUp(() {
      final style = StrokeStyle.pen(thickness: 2);
      lineTool = LineTool(style: style);
      rectangleTool = RectangleTool(style: style);
      ellipseTool = EllipseTool(style: style);
      arrowTool = ArrowTool(style: style);
    });

    group('LineTool', () {
      test('shapeType is line', () {
        expect(lineTool.shapeType, equals(ShapeType.line));
      });

      test('creates line shape', () {
        lineTool.startShape(DrawingPoint(x: 0, y: 0));
        lineTool.updateShape(DrawingPoint(x: 100, y: 100));

        final shape = lineTool.endShape();

        expect(shape, isNotNull);
        expect(shape!.type, equals(ShapeType.line));
      });
    });

    group('RectangleTool', () {
      test('shapeType is rectangle', () {
        expect(rectangleTool.shapeType, equals(ShapeType.rectangle));
      });

      test('isFilled respects constructor', () {
        final filledTool = RectangleTool(
          style: StrokeStyle.pen(),
          filled: true,
        );
        expect(filledTool.isFilled, isTrue);
        expect(rectangleTool.isFilled, isFalse);
      });

      test('creates rectangle shape', () {
        rectangleTool.startShape(DrawingPoint(x: 0, y: 0));
        rectangleTool.updateShape(DrawingPoint(x: 100, y: 50));

        final shape = rectangleTool.endShape();

        expect(shape, isNotNull);
        expect(shape!.type, equals(ShapeType.rectangle));
      });
    });

    group('EllipseTool', () {
      test('shapeType is ellipse', () {
        expect(ellipseTool.shapeType, equals(ShapeType.ellipse));
      });

      test('isFilled respects constructor', () {
        final filledTool = EllipseTool(
          style: StrokeStyle.pen(),
          filled: true,
        );
        expect(filledTool.isFilled, isTrue);
        expect(ellipseTool.isFilled, isFalse);
      });

      test('creates ellipse shape', () {
        ellipseTool.startShape(DrawingPoint(x: 0, y: 0));
        ellipseTool.updateShape(DrawingPoint(x: 100, y: 80));

        final shape = ellipseTool.endShape();

        expect(shape, isNotNull);
        expect(shape!.type, equals(ShapeType.ellipse));
      });
    });

    group('ArrowTool', () {
      test('shapeType is arrow', () {
        expect(arrowTool.shapeType, equals(ShapeType.arrow));
      });

      test('creates arrow shape', () {
        arrowTool.startShape(DrawingPoint(x: 0, y: 0));
        arrowTool.updateShape(DrawingPoint(x: 100, y: 50));

        final shape = arrowTool.endShape();

        expect(shape, isNotNull);
        expect(shape!.type, equals(ShapeType.arrow));
      });
    });

    group('common behavior', () {
      test('initial state is not drawing', () {
        expect(lineTool.isDrawing, isFalse);
        expect(lineTool.previewShape, isNull);
      });

      test('startShape begins drawing', () {
        lineTool.startShape(DrawingPoint(x: 10, y: 20));

        expect(lineTool.isDrawing, isTrue);
        expect(lineTool.startPoint?.x, equals(10));
      });

      test('updateShape updates current point', () {
        lineTool.startShape(DrawingPoint(x: 0, y: 0));
        lineTool.updateShape(DrawingPoint(x: 50, y: 60));

        expect(lineTool.currentPoint?.x, equals(50));
        expect(lineTool.currentPoint?.y, equals(60));
      });

      test('updateShape does nothing when not drawing', () {
        lineTool.updateShape(DrawingPoint(x: 50, y: 60));

        expect(lineTool.currentPoint, isNull);
      });

      test('previewShape available while drawing', () {
        lineTool.startShape(DrawingPoint(x: 0, y: 0));
        lineTool.updateShape(DrawingPoint(x: 100, y: 100));

        expect(lineTool.previewShape, isNotNull);
        expect(lineTool.previewShape!.type, equals(ShapeType.line));
      });

      test('cancelShape clears state', () {
        lineTool.startShape(DrawingPoint(x: 0, y: 0));
        lineTool.updateShape(DrawingPoint(x: 100, y: 100));
        lineTool.cancelShape();

        expect(lineTool.isDrawing, isFalse);
        expect(lineTool.startPoint, isNull);
        expect(lineTool.currentPoint, isNull);
      });

      test('endShape returns null for small shapes', () {
        lineTool.startShape(DrawingPoint(x: 0, y: 0));
        lineTool.updateShape(DrawingPoint(x: 2, y: 2));

        final shape = lineTool.endShape();

        expect(shape, isNull);
      });

      test('endShape clears state', () {
        lineTool.startShape(DrawingPoint(x: 0, y: 0));
        lineTool.updateShape(DrawingPoint(x: 100, y: 100));
        lineTool.endShape();

        expect(lineTool.isDrawing, isFalse);
        expect(lineTool.startPoint, isNull);
      });

      test('endShape returns null when not drawing', () {
        final shape = lineTool.endShape();
        expect(shape, isNull);
      });

      test('shape preserves style', () {
        lineTool.startShape(DrawingPoint(x: 0, y: 0));
        lineTool.updateShape(DrawingPoint(x: 100, y: 100));

        final shape = lineTool.endShape();

        expect(shape!.style.thickness, equals(2));
      });
    });
  });
}
