import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

Stroke _stroke(String id) => Stroke(
      id: id,
      points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
      style: StrokeStyle.pen(),
      createdAt: DateTime(2026),
    );

Shape _shape(String id) => Shape(
      id: id,
      type: ShapeType.rectangle,
      startPoint: DrawingPoint(x: 0, y: 0),
      endPoint: DrawingPoint(x: 10, y: 10),
      style: StrokeStyle.pen(),
    );

void main() {
  late HistoryManager manager;
  late DrawingDocument doc;

  // A layer with strokes s1, s2, shape r1 and an empty sticky note n1.
  setUp(() {
    manager = HistoryManager();
    doc = DrawingDocument.emptyMultiPage('Test');
    final base = doc.layers[0];
    final layer = base
        .addStroke(_stroke('s1'))
        .addStroke(_stroke('s2'))
        .addShape(_shape('r1'))
        .addStickyNote(StickyNote(id: 'n1', x: 0, y: 0, width: 50, height: 50));
    doc = doc.updateLayer(0, layer);
  });

  group('CompositeCommand', () {
    test('executes in order and undoes in reverse order', () {
      final cmd = CompositeCommand([
        AddStrokeCommand(layerIndex: 0, stroke: _stroke('s3')),
        RemoveStrokeCommand(layerIndex: 0, strokeId: 's3'),
      ]);
      final after = cmd.execute(doc);
      expect(after.layers[0].strokes.map((s) => s.id),
          unorderedEquals(['s1', 's2']));
      final undone = cmd.undo(after);
      expect(undone.layers[0].strokes.map((s) => s.id),
          unorderedEquals(['s1', 's2']));
      expect(cmd.description, 'Group (2)');
    });
  });

  group('HistoryManager groups', () {
    test('one eraser gesture (strokes, shapes, note) is one undo step', () {
      manager.beginGroup();
      doc = manager.execute(
        EraseStrokesCommand(layerIndex: 0, strokeIds: ['s1', 's2']),
        doc,
      );
      doc = manager.execute(
        RemoveShapeCommand(layerIndex: 0, shapeId: 'r1'),
        doc,
      );
      // A later command reads the state left by the earlier ones.
      final note = doc.layers[0].getStickyNoteById('n1')!;
      doc = manager.execute(
        UpdateStickyNoteCommand(
          layerIndex: 0,
          newNote: note.copyWith(color: 0xFF00FF00),
        ),
        doc,
      );
      expect(manager.undoCount, 0, reason: 'nothing recorded while open');
      manager.endGroup(description: 'Erase');

      expect(manager.undoCount, 1);
      expect(manager.getUndoDescriptions(), ['Erase']);
      expect(doc.layers[0].strokes, isEmpty);
      expect(doc.layers[0].shapes, isEmpty);

      final undone = manager.undo(doc)!;
      expect(manager.undoCount, 0);
      expect(undone.layers[0].strokes.map((s) => s.id),
          unorderedEquals(['s1', 's2']));
      expect(undone.layers[0].shapes.map((s) => s.id), ['r1']);
      expect(undone.layers[0].getStickyNoteById('n1')!.color, 0xFFFFF3CD);

      final redone = manager.redo(undone)!;
      expect(redone.layers[0].strokes, isEmpty);
      expect(redone.layers[0].shapes, isEmpty);
      expect(redone.layers[0].getStickyNoteById('n1')!.color, 0xFF00FF00);
    });

    test('an empty group records nothing', () {
      manager.beginGroup();
      manager.endGroup();
      expect(manager.undoCount, 0);
      expect(manager.isGrouping, isFalse);
    });

    test('a group of one command records that command', () {
      manager.beginGroup();
      doc = manager.execute(
        RemoveShapeCommand(layerIndex: 0, shapeId: 'r1'),
        doc,
      );
      manager.endGroup();
      expect(manager.undoCount, 1);
      expect(manager.getUndoDescriptions().single, isNot(startsWith('Group')));
    });

    test('nested groups record one step at the outermost end', () {
      manager.beginGroup();
      manager.beginGroup();
      doc = manager.execute(
        RemoveStrokeCommand(layerIndex: 0, strokeId: 's1'),
        doc,
      );
      manager.endGroup();
      expect(manager.isGrouping, isTrue);
      doc = manager.execute(
        RemoveStrokeCommand(layerIndex: 0, strokeId: 's2'),
        doc,
      );
      manager.endGroup();
      expect(manager.undoCount, 1);
      final undone = manager.undo(doc)!;
      expect(undone.layers[0].strokes.map((s) => s.id),
          unorderedEquals(['s1', 's2']));
    });

    test('a grouped step undoes on its own page after navigation', () {
      doc = doc.addPage(Page.create(index: 1));
      manager.beginGroup();
      doc = manager.execute(
        RemoveStrokeCommand(layerIndex: 0, strokeId: 's1'),
        doc,
      );
      doc = manager.execute(
        RemoveShapeCommand(layerIndex: 0, shapeId: 'r1'),
        doc,
      );
      manager.endGroup();

      final onPage2 = doc.setCurrentPage(1);
      final undone = manager.undo(onPage2)!;
      expect(undone.currentPageIndex, 0);
      expect(undone.layers[0].strokes.map((s) => s.id),
          unorderedEquals(['s1', 's2']));
      expect(undone.layers[0].shapes.map((s) => s.id), ['r1']);
    });

    test('ending a group that was never begun is a no-op', () {
      manager.endGroup();
      expect(manager.undoCount, 0);
    });
  });

  group('ElementIds', () {
    test('ids created in a tight loop are unique and increasing', () {
      final ids = [for (var i = 0; i < 1000; i++) ElementIds.next()];
      expect(ids.toSet(), hasLength(1000));
      final values = ids.map(int.parse).toList();
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThan(values[i - 1]));
      }
    });

    test('factory-created elements get distinct ids', () {
      final shapes = [
        for (var i = 0; i < 100; i++)
          Shape.create(
            type: ShapeType.rectangle,
            startPoint: DrawingPoint(x: 0, y: 0),
            endPoint: DrawingPoint(x: 1, y: 1),
            style: StrokeStyle.pen(),
          ),
      ];
      expect(shapes.map((s) => s.id).toSet(), hasLength(100));
    });
  });
}
