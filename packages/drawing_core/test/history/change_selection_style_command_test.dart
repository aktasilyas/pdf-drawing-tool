import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChangeSelectionStyleCommand shapes', () {
    late DrawingDocument document;
    late Shape filled;
    late Shape outline;
    late Stroke stroke;
    late TextElement text;

    setUp(() {
      filled = Shape.create(
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 10, y: 10),
        style: StrokeStyle.pen(color: 0xFF112233),
        isFilled: true,
        fillColor: 0x80112233,
      );
      outline = Shape.create(
        type: ShapeType.ellipse,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 5, y: 5),
        style: StrokeStyle.pen(color: 0xFF445566),
      );
      stroke = Stroke(
        id: 's',
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 1, y: 1)],
        style: StrokeStyle.pen(color: 0xFF000000),
        createdAt: DateTime(2026),
      );
      text = TextElement.create(text: 'a', x: 0, y: 0, color: 0xFF000000);
      final base = DrawingDocument.emptyMultiPage('T');
      final layer = base.layers[0]
          .addStroke(stroke)
          .addShape(filled)
          .addShape(outline)
          .addText(text);
      document = base.updateLayer(0, layer);
    });

    ChangeSelectionStyleCommand command() => ChangeSelectionStyleCommand(
          layerIndex: 0,
          strokeIds: [stroke.id],
          shapeIds: [filled.id, outline.id],
          textIds: [text.id],
          newColor: 0xFFFF0000,
        );

    test('recolors shapes, keeping fill alpha and null fill', () {
      final layer = command().execute(document).layers[0];
      expect(layer.shapes[0].style.color, 0xFFFF0000);
      expect(layer.shapes[0].fillColor, 0x80FF0000);
      expect(layer.shapes[1].style.color, 0xFFFF0000);
      expect(layer.shapes[1].fillColor, isNull);
    });

    test('mixed selection changes in one step and undo restores exactly', () {
      final cmd = command();
      final changed = cmd.execute(document).layers[0];
      expect(changed.strokes[0].style.color, 0xFFFF0000);
      expect(changed.texts[0].color, 0xFFFF0000);

      final undone = cmd.undo(cmd.execute(document)).layers[0];
      expect(undone.shapes[0], filled);
      expect(undone.shapes[1], outline);
      expect(undone.strokes[0].style.color, 0xFF000000);
      expect(undone.texts[0].color, 0xFF000000);
    });

    test('redo reapplies', () {
      final cmd = command();
      final redone = cmd.execute(cmd.undo(cmd.execute(document))).layers[0];
      expect(redone.shapes[0].fillColor, 0x80FF0000);
    });
  });
}
