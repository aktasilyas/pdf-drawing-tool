import 'package:test/test.dart';
import '../helpers/document_helpers.dart';
import 'clear_layer_command_test.dart' show fullLayer;
import 'package:drawing_core/src/history/clear_page_command.dart';
import 'package:drawing_core/src/models/layer.dart';

void main() {
  group('ClearPageCommand', () {
    test('empties every layer of the page', () {
      final document = multiPageDocWithLayers('Test', [
        fullLayer(),
        fullLayer().copyWith(id: 'l2', name: 'Layer 2'),
      ]);

      final cleared = ClearPageCommand().execute(document);

      expect(cleared.layers.length, 2);
      expect(cleared.layers.every((l) => l.isEmpty), isTrue);
      expect(cleared.layers.every((l) => l.elementOrder.isEmpty), isTrue);
      expect(cleared.layers[1].name, 'Layer 2');
    });

    test('one undo restores all layers', () {
      final original = [
        fullLayer(),
        fullLayer().copyWith(id: 'l2', name: 'Layer 2'),
      ];
      final document = multiPageDocWithLayers('Test', original);

      final command = ClearPageCommand();
      final restored = command.undo(command.execute(document));

      expect(
        restored.layers.map((l) => l.toJson()).toList(),
        original.map((l) => l.toJson()).toList(),
      );
    });

    test('undo before execute is a no-op', () {
      final document = multiPageDocWithLayers('Test', [Layer.empty('A')]);
      expect(ClearPageCommand().undo(document), same(document));
    });
  });
}
