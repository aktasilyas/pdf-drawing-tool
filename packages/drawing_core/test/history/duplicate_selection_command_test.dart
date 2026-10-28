import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('DuplicateSelectionCommand', () {
    late DrawingDocument document;
    late TextElement text;
    late ImageElement image;

    setUp(() {
      text = TextElement.create(
        text: 'Hello',
        x: 10,
        y: 20,
        fontSize: 22,
        color: 0xFF112233,
        fontFamily: 'Serif',
        isBold: true,
        isItalic: true,
        isUnderline: true,
        alignment: TextAlignment.center,
        width: 120,
        height: 60,
        rotation: 0.5,
      );
      image = ImageElement.create(
        filePath: '/tmp/a.png',
        x: 5,
        y: 6,
        width: 80,
        height: 40,
        rotation: 1.0,
      );
      final base = DrawingDocument.emptyMultiPage('T');
      final layer = base.layers[0].addText(text).addImage(image);
      document = base.updateLayer(0, layer);
    });

    DuplicateSelectionCommand command() => DuplicateSelectionCommand(
          layerIndex: 0,
          strokeIds: const [],
          imageIds: [image.id],
          textIds: [text.id],
          offsetX: 15,
          offsetY: 25,
        );

    test('duplicated text keeps every field except id and position', () {
      final result = command().execute(document);

      final copy = result.layers[0].texts.firstWhere((t) => t.id != text.id);
      expect(copy.x, text.x + 15);
      expect(copy.y, text.y + 25);
      expect(copy.copyWith(id: text.id, x: text.x, y: text.y), text);
    });

    test('duplicated image keeps size and rotation', () {
      final result = command().execute(document);

      final copy = result.layers[0].images.firstWhere((i) => i.id != image.id);
      expect(copy.x, image.x + 15);
      expect(copy.y, image.y + 25);
      expect(copy.width, image.width);
      expect(copy.height, image.height);
      expect(copy.rotation, image.rotation);
      expect(copy.filePath, image.filePath);
    });

    test('undo removes only the copies and redo restores them', () {
      final cmd = command();
      final executed = cmd.execute(document);
      expect(executed.layers[0].texts.length, 2);
      expect(executed.layers[0].images.length, 2);

      final undone = cmd.undo(executed);
      expect(undone.layers[0].texts.map((t) => t.id), [text.id]);
      expect(undone.layers[0].images.map((i) => i.id), [image.id]);

      final redone = cmd.execute(undone);
      expect(redone.layers[0].texts.length, 2);
      expect(redone.layers[0].images.length, 2);
    });
  });
}
