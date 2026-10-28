import 'package:test/test.dart';
import '../helpers/document_helpers.dart';
import 'package:drawing_core/src/history/clear_layer_command.dart';
import 'package:drawing_core/src/models/document.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/image_element.dart';
import 'package:drawing_core/src/models/shape.dart';
import 'package:drawing_core/src/models/shape_type.dart';
import 'package:drawing_core/src/models/sticky_note.dart';
import 'package:drawing_core/src/models/text_element.dart';

/// A layer holding all five element types, in a mixed z-order.
Layer fullLayer() {
  final style = StrokeStyle(thickness: 2.0, color: 0xFF000000);
  final stroke = Stroke(
    id: 's1',
    points: [
      DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
      DrawingPoint(x: 10, y: 10, pressure: 1.0, timestamp: 1),
    ],
    style: style,
    createdAt: DateTime.utc(2026),
  );
  final shape = Shape(
    id: 'sh1',
    type: ShapeType.rectangle,
    startPoint: DrawingPoint(x: 20, y: 20),
    endPoint: DrawingPoint(x: 40, y: 40),
    style: style,
  );
  final text = TextElement(id: 't1', text: 'hello', x: 5, y: 50);
  final image = ImageElement(
      id: 'i1', filePath: 'images/a.png', x: 60, y: 60, width: 30, height: 20);
  final note = StickyNote(id: 'n1', x: 80, y: 80, width: 200, height: 200);
  return Layer.empty('Layer 1').copyWith(
    strokes: [stroke],
    shapes: [shape],
    texts: [text],
    images: [image],
    stickyNotes: [note],
    elementOrder: ['i1', 's1', 'n1', 'sh1', 't1'],
  );
}

void main() {
  group('ClearLayerCommand', () {
    test('execute clears all content from layer', () {
      final stroke = Stroke(
        id: 'test',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 10, y: 10, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );

      final document = multiPageDocWithLayers('Test', [
        Layer.empty('Layer 1').copyWith(strokes: [stroke])
      ]);

      final command = ClearLayerCommand(layerIndex: 0);
      final result = command.execute(document);

      expect(result.layers[0].strokes, isEmpty);
    });

    test('undo restores original content', () {
      final stroke = Stroke(
        id: 'test',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 10, y: 10, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );

      final document = multiPageDocWithLayers('Test', [
        Layer.empty('Layer 1').copyWith(strokes: [stroke])
      ]);

      final command = ClearLayerCommand(layerIndex: 0);
      final clearedDoc = command.execute(document);
      final restoredDoc = command.undo(clearedDoc);

      expect(restoredDoc.layers[0].strokes.length, equals(1));
      expect(restoredDoc.layers[0].strokes.first.id, equals('test'));
    });

    test('execute removes every element type and the z-order (#424)', () {
      final document = multiPageDocWithLayers('Test', [fullLayer()]);

      final cleared = ClearLayerCommand(layerIndex: 0).execute(document);
      final layer = cleared.layers[0];

      expect(layer.strokes, isEmpty);
      expect(layer.shapes, isEmpty);
      expect(layer.texts, isEmpty);
      expect(layer.images, isEmpty);
      expect(layer.stickyNotes, isEmpty);
      expect(layer.elementOrder, isEmpty);
      expect(layer.isEmpty, isTrue);
    });

    test('undo restores all five element types and their order (#424)', () {
      final original = fullLayer();
      final document = multiPageDocWithLayers('Test', [original]);

      final command = ClearLayerCommand(layerIndex: 0);
      final restored = command.undo(command.execute(document)).layers[0];

      expect(restored.toJson(), original.toJson());
      expect(restored.elementOrder, ['i1', 's1', 'n1', 'sh1', 't1']);
    });

    test('handles invalid layer index gracefully', () {
      final document = DrawingDocument.emptyMultiPage('Test');

      final command = ClearLayerCommand(layerIndex: 99);
      final result = command.execute(document);

      expect(result, equals(document));
    });
  });
}
