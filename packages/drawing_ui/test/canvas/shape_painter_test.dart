import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShapePainter', () {
    test('creates without error', () {
      final painter = ShapePainter(shapes: const []);
      expect(painter, isNotNull);
    });

    test('shouldRepaint returns true when shapes change', () {
      final shape1 = Shape.create(
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 100, y: 100),
        style: StrokeStyle.pen(),
      );

      final shape2 = Shape.create(
        type: ShapeType.ellipse,
        startPoint: DrawingPoint(x: 50, y: 50),
        endPoint: DrawingPoint(x: 150, y: 150),
        style: StrokeStyle.pen(),
      );

      final painter1 = ShapePainter(shapes: [shape1]);
      final painter2 = ShapePainter(shapes: [shape1, shape2]);

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('shouldRepaint returns false when same list reference', () {
      final shape = Shape.create(
        type: ShapeType.line,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 100, y: 100),
        style: StrokeStyle.pen(),
      );

      final shapeList = [shape];
      final painter1 = ShapePainter(shapes: shapeList);
      final painter2 = ShapePainter(shapes: shapeList);

      expect(painter2.shouldRepaint(painter1), isFalse);
    });

    test('shouldRepaint returns true when activeShape changes', () {
      final shape = Shape.create(
        type: ShapeType.arrow,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 50, y: 50),
        style: StrokeStyle.pen(),
      );

      final painter1 = ShapePainter(shapes: const [], activeShape: null);
      final painter2 = ShapePainter(shapes: const [], activeShape: shape);

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('shouldRepaint returns false when both activeShape null', () {
      final painter1 = ShapePainter(shapes: const [], activeShape: null);
      final painter2 = ShapePainter(shapes: const [], activeShape: null);

      expect(painter2.shouldRepaint(painter1), isFalse);
    });

    testWidgets('renders without error in CustomPaint', (tester) async {
      final shape = Shape.create(
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 10, y: 10),
        endPoint: DrawingPoint(x: 100, y: 100),
        style: StrokeStyle.pen(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: ShapePainter(shapes: [shape]),
            ),
          ),
        ),
      );

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all shape types', (tester) async {
      final shapes = [
        Shape.create(
          type: ShapeType.line,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 50, y: 50),
          style: StrokeStyle.pen(),
        ),
        Shape.create(
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 60, y: 0),
          endPoint: DrawingPoint(x: 100, y: 40),
          style: StrokeStyle.pen(),
        ),
        Shape.create(
          type: ShapeType.ellipse,
          startPoint: DrawingPoint(x: 0, y: 60),
          endPoint: DrawingPoint(x: 50, y: 100),
          style: StrokeStyle.pen(),
        ),
        Shape.create(
          type: ShapeType.arrow,
          startPoint: DrawingPoint(x: 60, y: 60),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: ShapePainter(shapes: shapes),
            ),
          ),
        ),
      );

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders active shape as preview', (tester) async {
      final activeShape = Shape.create(
        type: ShapeType.ellipse,
        startPoint: DrawingPoint(x: 10, y: 10),
        endPoint: DrawingPoint(x: 90, y: 90),
        style: StrokeStyle.pen(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: ShapePainter(
                shapes: const [],
                activeShape: activeShape,
              ),
            ),
          ),
        ),
      );

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders filled shapes', (tester) async {
      final shape = Shape.create(
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 10, y: 10),
        endPoint: DrawingPoint(x: 100, y: 100),
        style: StrokeStyle.pen(),
        isFilled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: ShapePainter(shapes: [shape]),
            ),
          ),
        ),
      );

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });
  });
}
