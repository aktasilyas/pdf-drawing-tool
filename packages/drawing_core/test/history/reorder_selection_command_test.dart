import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

import '../helpers/document_helpers.dart';

Stroke _stroke(String id) => Stroke(
      id: id,
      points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 1, y: 1)],
      style: StrokeStyle.pen(),
      createdAt: DateTime(2026),
    );

Shape _shape(String id) => Shape(
      id: id,
      type: ShapeType.rectangle,
      startPoint: DrawingPoint(x: 0, y: 0),
      endPoint: DrawingPoint(x: 5, y: 5),
      style: StrokeStyle.pen(),
    );

ImageElement _image(String id) => ImageElement(
    id: id, filePath: '$id.png', x: 0, y: 0, width: 10, height: 10);

TextElement _text(String id) => TextElement(id: id, text: id, x: 0, y: 0);

/// Interleaved layer: s0 r0 i0 s1 t0 s2 r1 i1 t1 s3.
Layer _mixedLayer() => Layer.empty('L')
    .addStroke(_stroke('s0'))
    .addShape(_shape('r0'))
    .addImage(_image('i0'))
    .addStroke(_stroke('s1'))
    .addText(_text('t0'))
    .addStroke(_stroke('s2'))
    .addShape(_shape('r1'))
    .addImage(_image('i1'))
    .addText(_text('t1'))
    .addStroke(_stroke('s3'));

List<String> _strokeIds(Layer l) => [for (final s in l.strokes) s.id];
List<String> _shapeIds(Layer l) => [for (final s in l.shapes) s.id];
List<String> _imageIds(Layer l) => [for (final i in l.images) i.id];
List<String> _textIds(Layer l) => [for (final t in l.texts) t.id];

ReorderSelectionCommand _mixedCommand(ReorderDirection direction) =>
    ReorderSelectionCommand(
      layerIndex: 0,
      strokeIds: ['s0', 's2'],
      shapeIds: ['r0'],
      imageIds: ['i0'],
      textIds: ['t0'],
      direction: direction,
    );

void main() {
  late DrawingDocument doc;

  setUp(() => doc = multiPageDocWithLayers('Test', [_mixedLayer()]));

  test('fixture has the expected interleaved order', () {
    expect(doc.layers[0].elementOrder,
        ['s0', 'r0', 'i0', 's1', 't0', 's2', 'r1', 'i1', 't1', 's3']);
  });

  group('ReorderSelectionCommand bringToFront', () {
    test('execute moves a mixed, non-contiguous selection to the end', () {
      final layer =
          _mixedCommand(ReorderDirection.bringToFront).execute(doc).layers[0];

      expect(_strokeIds(layer), ['s1', 's3', 's0', 's2']);
      expect(_shapeIds(layer), ['r1', 'r0']);
      expect(_imageIds(layer), ['i1', 'i0']);
      expect(_textIds(layer), ['t1', 't0']);
      expect(layer.elementOrder,
          ['s1', 'r1', 'i1', 't1', 's3', 's0', 'r0', 'i0', 't0', 's2']);
    });

    test('undo restores per-type lists and elementOrder exactly', () {
      final command = _mixedCommand(ReorderDirection.bringToFront);
      final undone = command.undo(command.execute(doc));

      expect(undone.layers[0], doc.layers[0]);
    });

    test('undo then redo reproduces the executed document', () {
      final command = _mixedCommand(ReorderDirection.bringToFront);
      final executed = command.execute(doc);
      final redone = command.execute(command.undo(executed));

      expect(redone.layers[0], executed.layers[0]);
      expect(command.undo(redone).layers[0], doc.layers[0]);
    });
  });

  group('ReorderSelectionCommand sendToBack', () {
    test('execute moves a mixed, non-contiguous selection to the start', () {
      final layer =
          _mixedCommand(ReorderDirection.sendToBack).execute(doc).layers[0];

      expect(_strokeIds(layer), ['s0', 's2', 's1', 's3']);
      expect(_shapeIds(layer), ['r0', 'r1']);
      expect(_imageIds(layer), ['i0', 'i1']);
      expect(_textIds(layer), ['t0', 't1']);
      expect(layer.elementOrder,
          ['s0', 'r0', 'i0', 't0', 's2', 's1', 'r1', 'i1', 't1', 's3']);
    });

    test('undo restores per-type lists and elementOrder exactly', () {
      final command = _mixedCommand(ReorderDirection.sendToBack);
      final undone = command.undo(command.execute(doc));

      expect(undone.layers[0], doc.layers[0]);
    });

    test('single element already at the back is a round-trip no-op', () {
      final command = ReorderSelectionCommand(
        layerIndex: 0,
        strokeIds: ['s0'],
        direction: ReorderDirection.sendToBack,
      );
      final executed = command.execute(doc);

      expect(executed.layers[0], doc.layers[0]);
      expect(command.undo(executed).layers[0], doc.layers[0]);
    });
  });

  group('ReorderSelectionCommand edge cases', () {
    test('legacy layer without elementOrder keeps it empty on undo', () {
      final legacy = _mixedLayer().copyWith(elementOrder: const []);
      final legacyDoc = multiPageDocWithLayers('Legacy', [legacy]);
      final command = ReorderSelectionCommand(
        layerIndex: 0,
        strokeIds: ['s1', 's3'],
        direction: ReorderDirection.sendToBack,
      );

      final executed = command.execute(legacyDoc);
      expect(_strokeIds(executed.layers[0]), ['s1', 's3', 's0', 's2']);
      expect(executed.layers[0].elementOrder, isEmpty);

      expect(command.undo(executed).layers[0], legacy);
    });

    test('unknown ids are ignored and undo still restores the layer', () {
      final command = ReorderSelectionCommand(
        layerIndex: 0,
        strokeIds: ['s1', 'missing'],
        textIds: ['gone'],
        direction: ReorderDirection.bringToFront,
      );
      final executed = command.execute(doc);

      expect(_strokeIds(executed.layers[0]), ['s0', 's2', 's3', 's1']);
      expect(executed.layers[0].elementOrder.last, 's1');
      expect(command.undo(executed).layers[0], doc.layers[0]);
    });

    test('works through HistoryManager undo/redo', () {
      final history = HistoryManager();
      final executed = history.execute(
          _mixedCommand(ReorderDirection.bringToFront), doc);
      final undone = history.undo(executed)!;
      final redone = history.redo(undone)!;

      expect(undone.layers[0], doc.layers[0]);
      expect(redone.layers[0], executed.layers[0]);
    });

    test('description names direction and element count', () {
      expect(_mixedCommand(ReorderDirection.bringToFront).description,
          'Bring to front 5 element(s)');
      expect(_mixedCommand(ReorderDirection.sendToBack).description,
          'Send to back 5 element(s)');
    });
  });
}
