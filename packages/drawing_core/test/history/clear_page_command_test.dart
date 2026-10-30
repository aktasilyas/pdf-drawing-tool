import 'package:test/test.dart';
import '../helpers/document_helpers.dart';
import 'clear_layer_command_test.dart' show fullLayer;
import 'package:drawing_core/src/history/clear_page_command.dart';
import 'package:drawing_core/src/history/history_manager.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/page.dart';

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

    test('isNoop is true only when every layer is empty', () {
      expect(ClearPageCommand.isNoop([]), isTrue);
      expect(ClearPageCommand.isNoop([Layer.empty('A'), Layer.empty('B')]),
          isTrue);
      expect(ClearPageCommand.isNoop([Layer.empty('A'), fullLayer()]), isFalse);
    });

    test('guarded empty page creates no history entry', () {
      final document = multiPageDocWithLayers('Test', [Layer.empty('A')]);
      final history = HistoryManager();

      if (!ClearPageCommand.isNoop(document.layers)) {
        history.execute(ClearPageCommand(), document);
      }

      expect(history.canUndo, isFalse);
    });

    test('pageId targets another page, one undo restores it', () {
      final base = multiPageDocWithLayers('Test', [
        fullLayer(),
        fullLayer().copyWith(id: 'l2', name: 'Layer 2'),
      ]);
      final withTarget = base.addPage(
        Page.create(index: 1).copyWith(layers: [fullLayer()]),
      );
      final document = withTarget.copyWith(
        currentPageIndex: 0,
        activeLayerIndex: 1,
      );
      final targetId = document.pages[1].id;
      final history = HistoryManager();

      final cleared = history.execute(
        ClearPageCommand(),
        document,
        pageId: targetId,
      );

      expect(cleared.pages[1].layers.every((l) => l.isEmpty), isTrue);
      expect(
        cleared.pages[0].layers.map((l) => l.toJson()).toList(),
        document.pages[0].layers.map((l) => l.toJson()).toList(),
      );
      expect(cleared.currentPageIndex, 0);

      final restored = history.undo(cleared)!;
      expect(
        restored.pages[1].layers.map((l) => l.toJson()).toList(),
        document.pages[1].layers.map((l) => l.toJson()).toList(),
      );
      expect(history.canUndo, isFalse);
    });
  });
}
