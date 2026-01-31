import 'package:drawing_core/src/history/add_shape_command.dart';
import 'package:drawing_core/src/history/remove_shape_command.dart';
import 'package:drawing_core/src/models/document.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/shape.dart';
import 'package:drawing_core/src/models/shape_type.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:test/test.dart';

void main() {
  group('AddShapeCommand', () {
    late DrawingDocument document;
    late Shape shape;

    setUp(() {
      final layer = Layer.empty('Layer 1');
      document = DrawingDocument.emptyMultiPage('Test').copyWith(
        layers: [layer],
      );

      shape = Shape.create(
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 100, y: 100),
        style: StrokeStyle.pen(),
      );
    });

    test('execute adds shape to layer', () {
      final command = AddShapeCommand(
        layerIndex: 0,
        shape: shape,
      );

      final result = command.execute(document);

      expect(result.layers[0].shapes.length, equals(1));
      expect(result.layers[0].shapes.first.id, equals(shape.id));
    });

    test('undo removes added shape', () {
      final command = AddShapeCommand(
        layerIndex: 0,
        shape: shape,
      );

      final afterAdd = command.execute(document);
      final afterUndo = command.undo(afterAdd);

      expect(afterUndo.layers[0].shapes.length, equals(0));
    });

    test('description includes shape type', () {
      final command = AddShapeCommand(
        layerIndex: 0,
        shape: shape,
      );

      expect(command.description, equals('Add rectangle'));
    });

    test('handles invalid layer index', () {
      final command = AddShapeCommand(
        layerIndex: 99,
        shape: shape,
      );

      final result = command.execute(document);

      // Document unchanged
      expect(result.layers[0].shapes.length, equals(0));
    });

    test('handles negative layer index', () {
      final command = AddShapeCommand(
        layerIndex: -1,
        shape: shape,
      );

      final result = command.execute(document);

      // Document unchanged
      expect(result.layers[0].shapes.length, equals(0));
    });
  });

  group('RemoveShapeCommand', () {
    late DrawingDocument document;
    late Shape shape;

    setUp(() {
      shape = Shape.create(
        type: ShapeType.ellipse,
        startPoint: DrawingPoint(x: 10, y: 10),
        endPoint: DrawingPoint(x: 50, y: 50),
        style: StrokeStyle.pen(),
      );

      final layer = Layer.empty('Layer 1').addShape(shape);
      document = DrawingDocument.emptyMultiPage('Test').copyWith(
        layers: [layer],
      );
    });

    test('execute removes shape from layer', () {
      final command = RemoveShapeCommand(
        layerIndex: 0,
        shapeId: shape.id,
      );

      final result = command.execute(document);

      expect(result.layers[0].shapes.length, equals(0));
    });

    test('undo restores removed shape', () {
      final command = RemoveShapeCommand(
        layerIndex: 0,
        shapeId: shape.id,
      );

      final afterRemove = command.execute(document);
      final afterUndo = command.undo(afterRemove);

      expect(afterUndo.layers[0].shapes.length, equals(1));
      expect(afterUndo.layers[0].shapes.first.id, equals(shape.id));
    });

    test('handles non-existent shape gracefully', () {
      final command = RemoveShapeCommand(
        layerIndex: 0,
        shapeId: 'non-existent',
      );

      final result = command.execute(document);

      // Shape hala orada (silinecek bir şey yoktu)
      expect(result.layers[0].shapes.length, equals(1));
    });

    test('handles invalid layer index', () {
      final command = RemoveShapeCommand(
        layerIndex: 99,
        shapeId: shape.id,
      );

      final result = command.execute(document);

      // Document unchanged
      expect(result.layers[0].shapes.length, equals(1));
    });

    test('description is correct', () {
      final command = RemoveShapeCommand(
        layerIndex: 0,
        shapeId: shape.id,
      );

      expect(command.description, equals('Remove shape'));
    });
  });
}
