import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('MoveSelectionCommand', () {
    late DrawingDocument document;
    late Stroke stroke1;
    late Stroke stroke2;

    setUp(() {
      stroke1 = Stroke(
        id: 'stroke1',
        points: [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 10),
        ],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      stroke2 = Stroke(
        id: 'stroke2',
        points: [
          DrawingPoint(x: 100, y: 100),
          DrawingPoint(x: 110, y: 110),
        ],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      var layer = Layer.empty('Layer 1').addStroke(stroke1).addStroke(stroke2);

      document = DrawingDocument.emptyMultiPage('Test').copyWith(
        layers: [layer],
      );
    });

    test('execute moves stroke points by delta', () {
      final command = MoveSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1'],
        deltaX: 50,
        deltaY: 50,
      );

      final result = command.execute(document);
      final movedStroke = result.layers[0].strokes.firstWhere(
        (s) => s.id == 'stroke1',
      );

      expect(movedStroke.points[0].x, equals(50));
      expect(movedStroke.points[0].y, equals(50));
      expect(movedStroke.points[1].x, equals(60));
      expect(movedStroke.points[1].y, equals(60));
    });

    test('execute preserves pressure and tilt', () {
      final strokeWithPressure = Stroke(
        id: 'stroke-pressure',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 0.5, tilt: 0.2),
        ],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      var layer = Layer.empty('Layer').addStroke(strokeWithPressure);
      var doc = DrawingDocument.emptyMultiPage('Test').copyWith(layers: [layer]);

      final command = MoveSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke-pressure'],
        deltaX: 10,
        deltaY: 10,
      );

      final result = command.execute(doc);
      final moved = result.layers[0].strokes.first;

      expect(moved.points[0].pressure, equals(0.5));
      expect(moved.points[0].tilt, equals(0.2));
    });

    test('execute moves multiple strokes', () {
      final command = MoveSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1', 'stroke2'],
        deltaX: 25,
        deltaY: 25,
      );

      final result = command.execute(document);

      final moved1 =
          result.layers[0].strokes.firstWhere((s) => s.id == 'stroke1');
      final moved2 =
          result.layers[0].strokes.firstWhere((s) => s.id == 'stroke2');

      expect(moved1.points[0].x, equals(25));
      expect(moved1.points[0].y, equals(25));
      expect(moved2.points[0].x, equals(125));
      expect(moved2.points[0].y, equals(125));
    });

    test('execute ignores non-existent stroke ids', () {
      final command = MoveSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1', 'non-existent'],
        deltaX: 50,
        deltaY: 50,
      );

      final result = command.execute(document);

      // stroke1 should be moved
      final moved = result.layers[0].strokes.firstWhere(
        (s) => s.id == 'stroke1',
      );
      expect(moved.points[0].x, equals(50));

      // stroke2 should be unchanged
      final unchanged = result.layers[0].strokes.firstWhere(
        (s) => s.id == 'stroke2',
      );
      expect(unchanged.points[0].x, equals(100));
    });

    test('undo restores original positions', () {
      final command = MoveSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1'],
        deltaX: 50,
        deltaY: 50,
      );

      final afterMove = command.execute(document);
      final afterUndo = command.undo(afterMove);

      final restoredStroke = afterUndo.layers[0].strokes.firstWhere(
        (s) => s.id == 'stroke1',
      );

      expect(restoredStroke.points[0].x, equals(0));
      expect(restoredStroke.points[0].y, equals(0));
      expect(restoredStroke.points[1].x, equals(10));
      expect(restoredStroke.points[1].y, equals(10));
    });

    test('undo works with negative delta', () {
      final command = MoveSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1'],
        deltaX: -30,
        deltaY: -30,
      );

      final afterMove = command.execute(document);
      final afterUndo = command.undo(afterMove);

      final restoredStroke = afterUndo.layers[0].strokes.firstWhere(
        (s) => s.id == 'stroke1',
      );

      expect(restoredStroke.points[0].x, equals(0));
      expect(restoredStroke.points[0].y, equals(0));
    });

    test('description shows element count', () {
      final command = MoveSelectionCommand(
        layerIndex: 0,
        strokeIds: ['id1', 'id2'],
        deltaX: 10,
        deltaY: 10,
      );

      expect(command.description, equals('Move 2 element(s)'));
    });
  });

  group('DeleteSelectionCommand', () {
    late DrawingDocument document;
    late Stroke stroke1;
    late Stroke stroke2;
    late Stroke stroke3;

    setUp(() {
      stroke1 = Stroke(
        id: 'stroke1',
        points: [DrawingPoint(x: 0, y: 0)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      stroke2 = Stroke(
        id: 'stroke2',
        points: [DrawingPoint(x: 100, y: 100)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      stroke3 = Stroke(
        id: 'stroke3',
        points: [DrawingPoint(x: 200, y: 200)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      var layer = Layer.empty('Layer 1')
          .addStroke(stroke1)
          .addStroke(stroke2)
          .addStroke(stroke3);

      document = DrawingDocument.emptyMultiPage('Test').copyWith(
        layers: [layer],
      );
    });

    test('execute removes selected stroke', () {
      final command = DeleteSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1'],
      );

      final result = command.execute(document);

      expect(result.layers[0].strokes.length, equals(2));
      expect(result.layers[0].strokes.any((s) => s.id == 'stroke1'), isFalse);
      expect(result.layers[0].strokes.any((s) => s.id == 'stroke2'), isTrue);
      expect(result.layers[0].strokes.any((s) => s.id == 'stroke3'), isTrue);
    });

    test('execute removes multiple strokes', () {
      final command = DeleteSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1', 'stroke2'],
      );

      final result = command.execute(document);

      expect(result.layers[0].strokes.length, equals(1));
      expect(result.layers[0].strokes.any((s) => s.id == 'stroke3'), isTrue);
    });

    test('execute removes all strokes', () {
      final command = DeleteSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1', 'stroke2', 'stroke3'],
      );

      final result = command.execute(document);

      expect(result.layers[0].strokes.length, equals(0));
    });

    test('execute ignores non-existent stroke ids', () {
      final command = DeleteSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1', 'non-existent'],
      );

      final result = command.execute(document);

      expect(result.layers[0].strokes.length, equals(2));
      expect(result.layers[0].strokes.any((s) => s.id == 'stroke1'), isFalse);
    });

    test('undo restores deleted stroke', () {
      final command = DeleteSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1'],
      );

      final afterDelete = command.execute(document);
      expect(afterDelete.layers[0].strokes.length, equals(2));

      final afterUndo = command.undo(afterDelete);

      expect(afterUndo.layers[0].strokes.length, equals(3));
      expect(afterUndo.layers[0].strokes.any((s) => s.id == 'stroke1'), isTrue);
    });

    test('undo restores multiple strokes', () {
      final command = DeleteSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1', 'stroke2'],
      );

      final afterDelete = command.execute(document);
      final afterUndo = command.undo(afterDelete);

      expect(afterUndo.layers[0].strokes.length, equals(3));
      expect(afterUndo.layers[0].strokes.any((s) => s.id == 'stroke1'), isTrue);
      expect(afterUndo.layers[0].strokes.any((s) => s.id == 'stroke2'), isTrue);
    });

    test('undo restores stroke data correctly', () {
      final command = DeleteSelectionCommand(
        layerIndex: 0,
        strokeIds: ['stroke1'],
      );

      final afterDelete = command.execute(document);
      final afterUndo = command.undo(afterDelete);

      final restored = afterUndo.layers[0].strokes.firstWhere(
        (s) => s.id == 'stroke1',
      );

      expect(restored.points[0].x, equals(0));
      expect(restored.points[0].y, equals(0));
    });

    test('description shows element count', () {
      final command = DeleteSelectionCommand(
        layerIndex: 0,
        strokeIds: ['id1', 'id2', 'id3'],
      );

      expect(command.description, equals('Delete 3 element(s)'));
    });
  });
}
