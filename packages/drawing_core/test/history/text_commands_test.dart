import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('AddTextCommand', () {
    late DrawingDocument document;
    late TextElement text;

    setUp(() {
      document = DrawingDocument.emptyMultiPage('Test');
      text = TextElement.create(text: 'Hello', x: 50, y: 50);
    });

    test('execute adds text to layer', () {
      final command = AddTextCommand(layerIndex: 0, textElement: text);
      final result = command.execute(document);

      expect(result.layers[0].texts.length, equals(1));
      expect(result.layers[0].texts.first.text, equals('Hello'));
    });

    test('undo removes text', () {
      final command = AddTextCommand(layerIndex: 0, textElement: text);
      final afterAdd = command.execute(document);
      final afterUndo = command.undo(afterAdd);

      expect(afterUndo.layers[0].texts.length, equals(0));
    });

    test('description is correct', () {
      final command = AddTextCommand(layerIndex: 0, textElement: text);
      expect(command.description, equals('Add text'));
    });
  });

  group('RemoveTextCommand', () {
    late DrawingDocument document;
    late TextElement text;

    setUp(() {
      text = TextElement.create(text: 'Hello', x: 50, y: 50);
      final baseDoc = DrawingDocument.emptyMultiPage('Test');
      final layer = baseDoc.layers[0].addText(text);
      document = baseDoc.updateLayer(0, layer);
    });

    test('execute removes text from layer', () {
      final command = RemoveTextCommand(layerIndex: 0, textId: text.id);
      final result = command.execute(document);

      expect(result.layers[0].texts.length, equals(0));
    });

    test('undo restores text', () {
      final command = RemoveTextCommand(layerIndex: 0, textId: text.id);
      final afterRemove = command.execute(document);
      final afterUndo = command.undo(afterRemove);

      expect(afterUndo.layers[0].texts.length, equals(1));
      expect(afterUndo.layers[0].texts.first.text, equals('Hello'));
    });

    test('description is correct', () {
      final command = RemoveTextCommand(layerIndex: 0, textId: text.id);
      expect(command.description, equals('Remove text'));
    });
  });

  group('UpdateTextCommand', () {
    late DrawingDocument document;
    late TextElement text;

    setUp(() {
      text = TextElement.create(text: 'Original', x: 50, y: 50);
      final baseDoc = DrawingDocument.emptyMultiPage('Test');
      final layer = baseDoc.layers[0].addText(text);
      document = baseDoc.updateLayer(0, layer);
    });

    test('execute updates text', () {
      final newText = text.copyWith(text: 'Updated');
      final command = UpdateTextCommand(layerIndex: 0, newText: newText);
      final result = command.execute(document);

      expect(result.layers[0].texts.first.text, equals('Updated'));
    });

    test('undo restores original text', () {
      final newText = text.copyWith(text: 'Updated');
      final command = UpdateTextCommand(layerIndex: 0, newText: newText);
      final afterUpdate = command.execute(document);
      final afterUndo = command.undo(afterUpdate);

      expect(afterUndo.layers[0].texts.first.text, equals('Original'));
    });

    test('can update style properties', () {
      final newText = text.copyWith(
        fontSize: 24,
        isBold: true,
        color: 0xFFFF0000,
      );
      final command = UpdateTextCommand(layerIndex: 0, newText: newText);
      final result = command.execute(document);

      expect(result.layers[0].texts.first.fontSize, equals(24));
      expect(result.layers[0].texts.first.isBold, isTrue);
      expect(result.layers[0].texts.first.color, equals(0xFFFF0000));
    });

    test('description is correct', () {
      final newText = text.copyWith(text: 'Updated');
      final command = UpdateTextCommand(layerIndex: 0, newText: newText);
      expect(command.description, equals('Update text'));
    });
  });
}
