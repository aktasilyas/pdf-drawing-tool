import 'package:test/test.dart';
import 'package:drawing_core/src/models/document.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/history/add_stroke_command.dart';
import 'package:drawing_core/src/history/remove_stroke_command.dart';

void main() {
  group('AddStrokeCommand', () {
    late DrawingDocument document;
    late Stroke testStroke;

    setUp(() {
      document = DrawingDocument.empty('Test Document');
      testStroke = Stroke(
        id: 'test-stroke',
        points: [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 10),
        ],
        style: StrokeStyle.pen(),
        createdAt: DateTime(2024, 1, 1),
      );
    });

    group('execute', () {
      test('adds stroke to layer', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: testStroke,
        );

        expect(document.strokeCount, 0);

        final result = command.execute(document);

        expect(result.strokeCount, 1);
        expect(result.layers[0].strokes[0].id, 'test-stroke');
      });

      test('increments strokeCount', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: testStroke,
        );

        final result = command.execute(document);

        expect(document.strokeCount, 0); // original unchanged
        expect(result.strokeCount, 1);
      });

      test('handles invalid layer index', () {
        final command = AddStrokeCommand(
          layerIndex: 5, // invalid
          stroke: testStroke,
        );

        final result = command.execute(document);

        expect(result.strokeCount, 0);
      });

      test('handles negative layer index', () {
        final command = AddStrokeCommand(
          layerIndex: -1,
          stroke: testStroke,
        );

        final result = command.execute(document);

        expect(result.strokeCount, 0);
      });
    });

    group('undo', () {
      test('removes stroke from layer', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: testStroke,
        );

        final executed = command.execute(document);
        expect(executed.strokeCount, 1);

        final undone = command.undo(executed);
        expect(undone.strokeCount, 0);
      });

      test('decrements strokeCount', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: testStroke,
        );

        final executed = command.execute(document);
        final undone = command.undo(executed);

        expect(executed.strokeCount, 1);
        expect(undone.strokeCount, 0);
      });

      test('handles invalid layer index', () {
        final command = AddStrokeCommand(
          layerIndex: 5, // invalid
          stroke: testStroke,
        );

        final result = command.undo(document);

        expect(result.strokeCount, 0);
      });
    });

    group('description', () {
      test('returns correct description', () {
        final command = AddStrokeCommand(
          layerIndex: 2,
          stroke: testStroke,
        );

        expect(command.description, 'Add stroke to layer 2');
      });
    });

    group('roundtrip', () {
      test('execute then undo returns to original state', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: testStroke,
        );

        final executed = command.execute(document);
        final undone = command.undo(executed);

        expect(undone.strokeCount, document.strokeCount);
        expect(undone.layers[0].strokeCount, document.layers[0].strokeCount);
      });
    });
  });

  group('RemoveStrokeCommand', () {
    late DrawingDocument document;
    late Stroke testStroke;

    setUp(() {
      testStroke = Stroke(
        id: 'stroke-to-remove',
        points: [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 10),
        ],
        style: StrokeStyle.pen(),
        createdAt: DateTime(2024, 1, 1),
      );

      final layer = Layer(
        id: 'layer-1',
        name: 'Layer 1',
        strokes: [testStroke],
      );

      document = DrawingDocument.withLayers('Test Document', [layer]);
    });

    group('execute', () {
      test('removes stroke from layer', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-to-remove',
        );

        expect(document.strokeCount, 1);

        final result = command.execute(document);

        expect(result.strokeCount, 0);
      });

      test('decrements strokeCount', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-to-remove',
        );

        final result = command.execute(document);

        expect(document.strokeCount, 1); // original unchanged
        expect(result.strokeCount, 0);
      });

      test('caches removed stroke', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-to-remove',
        );

        expect(command.removedStroke, isNull);

        command.execute(document);

        expect(command.removedStroke, isNotNull);
        expect(command.removedStroke!.id, 'stroke-to-remove');
      });

      test('handles non-existent stroke id', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'non-existent',
        );

        final result = command.execute(document);

        expect(result.strokeCount, 1); // unchanged
        expect(command.removedStroke, isNull);
      });

      test('handles invalid layer index', () {
        final command = RemoveStrokeCommand(
          layerIndex: 5, // invalid
          strokeId: 'stroke-to-remove',
        );

        final result = command.execute(document);

        expect(result.strokeCount, 1); // unchanged
      });

      test('handles negative layer index', () {
        final command = RemoveStrokeCommand(
          layerIndex: -1,
          strokeId: 'stroke-to-remove',
        );

        final result = command.execute(document);

        expect(result.strokeCount, 1); // unchanged
      });
    });

    group('undo', () {
      test('restores removed stroke', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-to-remove',
        );

        final executed = command.execute(document);
        expect(executed.strokeCount, 0);

        final undone = command.undo(executed);
        expect(undone.strokeCount, 1);
        expect(undone.layers[0].strokes[0].id, 'stroke-to-remove');
      });

      test('increments strokeCount', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-to-remove',
        );

        final executed = command.execute(document);
        final undone = command.undo(executed);

        expect(executed.strokeCount, 0);
        expect(undone.strokeCount, 1);
      });

      test('returns unchanged if no stroke was removed', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'non-existent',
        );

        // Execute finds nothing
        final executed = command.execute(document);
        expect(executed.strokeCount, 1);

        // Undo should return unchanged
        final undone = command.undo(executed);
        expect(undone.strokeCount, 1);
      });

      test('handles invalid layer index', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-to-remove',
        );

        // Execute on valid document
        command.execute(document);

        // Create document with no layers for undo
        final emptyDoc = DrawingDocument.empty('Empty');

        // Undo on document with different layer count
        final invalidCommand = RemoveStrokeCommand(
          layerIndex: 5,
          strokeId: 'any',
        );
        invalidCommand.execute(document);
        final result = invalidCommand.undo(emptyDoc);

        // Should return unchanged
        expect(result.layerCount, 1);
      });
    });

    group('description', () {
      test('returns correct description', () {
        final command = RemoveStrokeCommand(
          layerIndex: 1,
          strokeId: 'my-stroke-id',
        );

        expect(
          command.description,
          'Remove stroke my-stroke-id from layer 1',
        );
      });
    });

    group('roundtrip', () {
      test('execute then undo returns to original state', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-to-remove',
        );

        final executed = command.execute(document);
        final undone = command.undo(executed);

        expect(undone.strokeCount, document.strokeCount);
        expect(undone.layers[0].strokeCount, document.layers[0].strokeCount);
        expect(undone.layers[0].strokes[0].id, 'stroke-to-remove');
      });

      test('multiple execute/undo cycles work correctly', () {
        final command = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-to-remove',
        );

        // Cycle 1
        var current = command.execute(document);
        expect(current.strokeCount, 0);

        current = command.undo(current);
        expect(current.strokeCount, 1);

        // Cycle 2
        current = command.execute(current);
        expect(current.strokeCount, 0);

        current = command.undo(current);
        expect(current.strokeCount, 1);
      });
    });
  });

  group('Command integration', () {
    test('add then remove returns to original', () {
      final document = DrawingDocument.empty('Test');
      final stroke = Stroke(
        id: 'integration-stroke',
        points: [DrawingPoint(x: 5, y: 5)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      final addCommand = AddStrokeCommand(layerIndex: 0, stroke: stroke);
      final removeCommand = RemoveStrokeCommand(
        layerIndex: 0,
        strokeId: 'integration-stroke',
      );

      // Add stroke
      var current = addCommand.execute(document);
      expect(current.strokeCount, 1);

      // Remove stroke
      current = removeCommand.execute(current);
      expect(current.strokeCount, 0);

      // Undo remove
      current = removeCommand.undo(current);
      expect(current.strokeCount, 1);

      // Undo add
      current = addCommand.undo(current);
      expect(current.strokeCount, 0);
    });

    test('multiple strokes with commands', () {
      final document = DrawingDocument.empty('Test');

      final stroke1 = Stroke(
        id: 'stroke-1',
        points: [DrawingPoint(x: 0, y: 0)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      final stroke2 = Stroke(
        id: 'stroke-2',
        points: [DrawingPoint(x: 10, y: 10)],
        style: StrokeStyle.brush(),
        createdAt: DateTime.now(),
      );

      final add1 = AddStrokeCommand(layerIndex: 0, stroke: stroke1);
      final add2 = AddStrokeCommand(layerIndex: 0, stroke: stroke2);

      // Add both strokes
      var current = add1.execute(document);
      current = add2.execute(current);
      expect(current.strokeCount, 2);

      // Undo second add
      current = add2.undo(current);
      expect(current.strokeCount, 1);
      expect(current.layers[0].strokes[0].id, 'stroke-1');

      // Undo first add
      current = add1.undo(current);
      expect(current.strokeCount, 0);
    });
  });
}
