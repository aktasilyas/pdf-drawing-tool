import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

import '../helpers/document_helpers.dart';

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
      endPoint: DrawingPoint(x: 5, y: 5),
      style: StrokeStyle.pen(),
    );

TextElement _text(String id) => TextElement(id: id, text: id, x: 0, y: 0);

ImageElement _image(String id) => ImageElement(
      id: id,
      filePath: '$id.png',
      x: 0,
      y: 0,
      width: 10,
      height: 10,
    );

List<String> _ids(Iterable<dynamic> items) =>
    items.map((e) => e.id as String).toList();

void main() {
  final strokes = [
    for (final i in [1, 2, 3, 4, 5]) _stroke('s$i')
  ];
  final shapes = [
    for (final i in [1, 2, 3]) _shape('h$i')
  ];

  // Layer with an elementOrder and one without (legacy / imported JSON).
  final texts = [
    for (final i in [1, 2, 3]) _text('t$i')
  ];
  final images = [
    for (final i in [1, 2, 3]) _image('i$i')
  ];
  final withOrder = Layer.empty('L')
      .addStroke(strokes[0])
      .addText(texts[0])
      .addStroke(strokes[1])
      .addShape(shapes[0])
      .addImage(images[0])
      .addStroke(strokes[2])
      .addShape(shapes[1])
      .addText(texts[1])
      .addStroke(strokes[3])
      .addImage(images[1])
      .addShape(shapes[2])
      .addText(texts[2])
      .addImage(images[2])
      .addStroke(strokes[4]);
  final noOrder = withOrder.copyWith(elementOrder: const []);

  for (final entry in {
    'with elementOrder': withOrder,
    'empty elementOrder': noOrder
  }.entries) {
    group(entry.key, () {
      final layer = entry.value;
      late DrawingDocument doc;
      setUp(() => doc = multiPageDocWithLayers('T', [layer]));

      void expectSame(DrawingDocument after) {
        final l = after.layers[0];
        expect(_ids(l.strokes), _ids(layer.strokes));
        expect(_ids(l.shapes), _ids(layer.shapes));
        expect(_ids(l.texts), _ids(layer.texts));
        expect(_ids(l.images), _ids(layer.images));
        expect(l.elementOrder, layer.elementOrder);
      }

      test('RemoveStrokeCommand undo restores position', () {
        final cmd = RemoveStrokeCommand(layerIndex: 0, strokeId: 's2');
        final removed = cmd.execute(doc);
        expect(_ids(removed.layers[0].strokes), isNot(contains('s2')));
        expectSame(cmd.undo(removed));
      });

      test('EraseStrokesCommand undo restores positions', () {
        final cmd =
            EraseStrokesCommand(layerIndex: 0, strokeIds: ['s4', 's1', 's3']);
        expectSame(cmd.undo(cmd.execute(doc)));
      });

      test('DeleteSelectionCommand undo restores strokes and shapes', () {
        final cmd = DeleteSelectionCommand(
          layerIndex: 0,
          strokeIds: ['s5', 's2'],
          shapeIds: ['h3', 'h1'],
          textIds: ['t3', 't1'],
          imageIds: ['i3', 'i1'],
        );
        final removed = cmd.execute(doc);
        expect(_ids(removed.layers[0].strokes), ['s1', 's3', 's4']);
        expect(_ids(removed.layers[0].texts), ['t2']);
        expect(_ids(removed.layers[0].images), ['i2']);
        expectSame(cmd.undo(removed));
      });

      test('RemoveShapeCommand undo restores position', () {
        final cmd = RemoveShapeCommand(layerIndex: 0, shapeId: 'h2');
        final removed = cmd.execute(doc);
        expect(_ids(removed.layers[0].shapes), ['h1', 'h3']);
        expectSame(cmd.undo(removed));
      });

      test('RemoveTextCommand undo restores position', () {
        final cmd = RemoveTextCommand(layerIndex: 0, textId: 't2');
        final removed = cmd.execute(doc);
        expect(_ids(removed.layers[0].texts), ['t1', 't3']);
        expectSame(cmd.undo(removed));
      });

      test('RemoveImageCommand undo restores position', () {
        final cmd = RemoveImageCommand(layerIndex: 0, imageId: 'i2');
        final removed = cmd.execute(doc);
        expect(_ids(removed.layers[0].images), ['i1', 'i3']);
        expectSame(cmd.undo(removed));
      });
    });
  }

  group('no-ops', () {
    final layer = Layer.empty('L').addStroke(strokes[0]);
    late DrawingDocument doc;
    setUp(() => doc = multiPageDocWithLayers('T', [layer]));

    final commands = <String, DrawingCommand Function(int)>{
      'RemoveStrokeCommand': (i) =>
          RemoveStrokeCommand(layerIndex: i, strokeId: 's1'),
      'EraseStrokesCommand': (i) =>
          EraseStrokesCommand(layerIndex: i, strokeIds: ['s1']),
      'DeleteSelectionCommand': (i) =>
          DeleteSelectionCommand(layerIndex: i, strokeIds: ['s1']),
      'RemoveShapeCommand': (i) =>
          RemoveShapeCommand(layerIndex: i, shapeId: 'h1'),
      'RemoveTextCommand': (i) =>
          RemoveTextCommand(layerIndex: i, textId: 't1'),
      'RemoveImageCommand': (i) =>
          RemoveImageCommand(layerIndex: i, imageId: 'i1'),
    };

    for (final e in commands.entries) {
      test('${e.key} undo before execute leaves document unchanged', () {
        expect(e.value(0).undo(doc), same(doc));
      });

      for (final bad in [-1, 5]) {
        test('${e.key} with layerIndex $bad is a no-op', () {
          final cmd = e.value(bad);
          expect(cmd.execute(doc), same(doc));
          expect(cmd.undo(doc), same(doc));
        });
      }
    }
  });
}
