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
      endPoint: DrawingPoint(x: 10, y: 10),
      style: StrokeStyle.pen(),
    );

TextElement _text(String id) => TextElement(id: id, text: id, x: 0, y: 0);

ImageElement _image(String id) => ImageElement(
      id: id,
      filePath: '/tmp/$id.png',
      x: 0,
      y: 0,
      width: 10,
      height: 10,
    );

/// Layer with interleaved elements so every removal is from the middle.
Layer _mixedLayer() => Layer.empty('L')
    .addStroke(_stroke('s1'))
    .addShape(_shape('r1'))
    .addStroke(_stroke('s2'))
    .addText(_text('t1'))
    .addImage(_image('i1'))
    .addStroke(_stroke('s3'))
    .addShape(_shape('r2'))
    .addText(_text('t2'))
    .addImage(_image('i2'))
    .addStroke(_stroke('s4'));

/// Same content as [_mixedLayer] but without an elementOrder (legacy JSON).
Layer _legacyLayer() => _mixedLayer().copyWith(elementOrder: const []);

List<String> _strokeIds(Layer l) => [for (final e in l.strokes) e.id];
List<String> _shapeIds(Layer l) => [for (final e in l.shapes) e.id];
List<String> _textIds(Layer l) => [for (final e in l.texts) e.id];
List<String> _imageIds(Layer l) => [for (final e in l.images) e.id];

void _expectSameOrder(Layer actual, Layer expected) {
  expect(_strokeIds(actual), _strokeIds(expected), reason: 'strokes');
  expect(_shapeIds(actual), _shapeIds(expected), reason: 'shapes');
  expect(_textIds(actual), _textIds(expected), reason: 'texts');
  expect(_imageIds(actual), _imageIds(expected), reason: 'images');
  expect(actual.elementOrder, expected.elementOrder, reason: 'elementOrder');
  expect(actual, expected);
}

void main() {
  final variants = <String, Layer Function()>{
    'with elementOrder': _mixedLayer,
    'with empty elementOrder': _legacyLayer,
  };

  for (final entry in variants.entries) {
    group('undo restores original order (${entry.key})', () {
      late Layer original;
      late DrawingDocument doc;

      setUp(() {
        original = entry.value();
        doc = multiPageDocWithLayers('T', [original]);
      });

      test('DeleteSelectionCommand', () {
        final command = DeleteSelectionCommand(
          layerIndex: 0,
          // Deliberately not in list order.
          strokeIds: ['s3', 's1', 's4'],
          shapeIds: ['r2', 'r1'],
          imageIds: ['i1'],
          textIds: ['t2', 't1'],
        );

        final restored = command.undo(command.execute(doc));

        _expectSameOrder(restored.layers[0], original);
      });

      test('DeleteSelectionCommand ignores unknown ids', () {
        final command = DeleteSelectionCommand(
          layerIndex: 0,
          strokeIds: ['s2', 'missing'],
          shapeIds: ['nope'],
        );

        final restored = command.undo(command.execute(doc));

        _expectSameOrder(restored.layers[0], original);
      });

      test('EraseStrokesCommand', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: ['s4', 's2', 's1'],
        );

        final restored = command.undo(command.execute(doc));

        _expectSameOrder(restored.layers[0], original);
      });

      test('RemoveStrokeCommand', () {
        final command = RemoveStrokeCommand(layerIndex: 0, strokeId: 's2');

        final restored = command.undo(command.execute(doc));

        _expectSameOrder(restored.layers[0], original);
      });

      test('redo after undo removes the same elements again', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: ['s1', 's3'],
        );

        final once = command.execute(doc);
        final again = command.execute(command.undo(once));

        _expectSameOrder(again.layers[0], once.layers[0]);
      });
    });
  }

  group('undo before execute leaves the document unchanged', () {
    final doc = multiPageDocWithLayers('T', [_mixedLayer()]);
    final commands = <DrawingCommand>[
      DeleteSelectionCommand(layerIndex: 0, strokeIds: ['s1']),
      EraseStrokesCommand(layerIndex: 0, strokeIds: ['s1']),
      RemoveStrokeCommand(layerIndex: 0, strokeId: 's1'),
    ];

    for (final command in commands) {
      test(command.runtimeType.toString(), () {
        expect(command.undo(doc), same(doc));
      });
    }
  });

  test('out-of-range layerIndex is a no-op for execute and undo', () {
    final doc = multiPageDocWithLayers('T', [_mixedLayer()]);
    final command = DeleteSelectionCommand(layerIndex: 3, strokeIds: ['s1']);

    expect(command.execute(doc), same(doc));
    expect(command.undo(doc), same(doc));
  });
}
