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
  final withOrder = Layer.empty('L')
      .addStroke(strokes[0])
      .addStroke(strokes[1])
      .addShape(shapes[0])
      .addStroke(strokes[2])
      .addShape(shapes[1])
      .addStroke(strokes[3])
      .addShape(shapes[2])
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
        );
        final removed = cmd.execute(doc);
        expect(_ids(removed.layers[0].strokes), ['s1', 's3', 's4']);
        expectSame(cmd.undo(removed));
      });
    });
  }
}
