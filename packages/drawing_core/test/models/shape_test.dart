import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/shape.dart';
import 'package:drawing_core/src/models/shape_type.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:test/test.dart';

void main() {
  group('Shape', () {
    group('creation', () {
      test('factory creates with unique id', () {
        final shape1 = Shape.create(
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(),
        );

        final shape2 = Shape.create(
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(),
        );

        expect(shape1.id, isNot(equals(shape2.id)));
      });
    });

    group('properties', () {
      test('width and height calculated correctly', () {
        final shape = Shape.create(
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 10, y: 20),
          endPoint: DrawingPoint(x: 110, y: 80),
          style: StrokeStyle.pen(),
        );

        expect(shape.width, equals(100));
        expect(shape.height, equals(60));
      });

      test('center calculated correctly', () {
        final shape = Shape.create(
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(),
        );

        expect(shape.centerX, equals(50));
        expect(shape.centerY, equals(50));
      });

      test('bounds includes stroke thickness', () {
        final shape = Shape.create(
          type: ShapeType.line,
          startPoint: DrawingPoint(x: 10, y: 10),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(thickness: 10),
        );

        expect(shape.bounds.left, equals(5)); // 10 - 5
        expect(shape.bounds.top, equals(5));
      });
    });

    group('hit testing', () {
      test('line hit test works', () {
        final shape = Shape.create(
          type: ShapeType.line,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(thickness: 4),
        );

        // Çizgi üzerinde
        expect(shape.containsPoint(50, 50, 5), isTrue);
        // Çizgiden uzakta
        expect(shape.containsPoint(0, 100, 5), isFalse);
      });

      test('rectangle filled hit test works', () {
        final shape = Shape.create(
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(),
          isFilled: true,
        );

        // İçinde
        expect(shape.containsPoint(50, 50, 5), isTrue);
        // Dışında
        expect(shape.containsPoint(150, 150, 5), isFalse);
      });

      test('rectangle stroke hit test works', () {
        final shape = Shape.create(
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(thickness: 4),
          isFilled: false,
        );

        // Kenar üzerinde
        expect(shape.containsPoint(0, 50, 5), isTrue);
        // İçinde ama kenarda değil
        expect(shape.containsPoint(50, 50, 2), isFalse);
      });

      test('ellipse hit test works', () {
        final shape = Shape.create(
          type: ShapeType.ellipse,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 100, y: 100),
          style: StrokeStyle.pen(),
          isFilled: true,
        );

        // Merkezde
        expect(shape.containsPoint(50, 50, 5), isTrue);
        // Köşede (elips dışında)
        expect(shape.containsPoint(5, 5, 2), isFalse);
      });
    });

    group('serialization', () {
      test('toJson and fromJson roundtrip', () {
        final shape = Shape.create(
          type: ShapeType.arrow,
          startPoint: DrawingPoint(x: 10, y: 20),
          endPoint: DrawingPoint(x: 100, y: 200),
          style: StrokeStyle.pen(thickness: 3),
          isFilled: false,
        );

        final json = shape.toJson();
        final restored = Shape.fromJson(json);

        expect(restored.id, equals(shape.id));
        expect(restored.type, equals(shape.type));
        expect(restored.startPoint.x, equals(shape.startPoint.x));
        expect(restored.isFilled, equals(shape.isFilled));
      });
    });
  });

  group('ShapeType', () {
    test('has all expected values', () {
      expect(ShapeType.values, contains(ShapeType.line));
      expect(ShapeType.values, contains(ShapeType.rectangle));
      expect(ShapeType.values, contains(ShapeType.ellipse));
      expect(ShapeType.values, contains(ShapeType.arrow));
    });
  });
}
