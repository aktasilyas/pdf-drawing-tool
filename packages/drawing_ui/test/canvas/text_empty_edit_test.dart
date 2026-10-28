// Emptying a text box while editing (#426): an existing text is removed with
// one history entry (undo restores it); an empty new text records nothing.
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DrawingCanvasState state;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DrawingCanvas())),
      ),
    );
    final finder = find.byType(DrawingCanvas);
    state = tester.state<DrawingCanvasState>(finder);
    container = ProviderScope.containerOf(tester.element(finder));
  }

  List<core.TextElement> texts() => container.read(activeLayerTextsProvider);
  int undoCount() => container.read(historyManagerProvider).undoCount;

  core.TextElement addExistingText() {
    final text = core.TextElement.create(text: 'Hello', x: 100, y: 100);
    container.read(historyManagerProvider.notifier).execute(
          core.AddTextCommand(
            layerIndex: container.read(documentProvider).activeLayerIndex,
            textElement: text,
          ),
        );
    return text;
  }

  void editTo(core.TextElement original, String value) {
    final notifier = container.read(textToolProvider.notifier);
    notifier.editExistingText(original);
    notifier.updateText(original.copyWith(text: value));
  }

  group('emptying a text box', () {
    for (final value in ['', '   ']) {
      testWidgets('existing text edited to "$value" is removed; undo restores',
          (tester) async {
        await pump(tester);
        final original = addExistingText();
        final before = undoCount();

        editTo(original, value);
        state.finishTextEditing();

        expect(container.read(textToolProvider).isEditing, isFalse);
        expect(texts(), isEmpty);
        expect(undoCount(), before + 1);

        container.read(historyManagerProvider.notifier).undo();
        expect(texts().single.id, original.id);
        expect(texts().single.text, 'Hello');
      });
    }

    testWidgets('overlay empty path (handleTextEmptied) removes existing text',
        (tester) async {
      await pump(tester);
      final original = addExistingText();
      final before = undoCount();

      editTo(original, '');
      state.handleTextEmptied();

      expect(container.read(textToolProvider).isEditing, isFalse);
      expect(texts(), isEmpty);
      expect(undoCount(), before + 1);
    });

    testWidgets('empty new text creates nothing and records no history',
        (tester) async {
      await pump(tester);
      container.read(currentToolProvider.notifier).selectTool(ToolType.text);
      final before = undoCount();

      state.handlePointerDown(
        const PointerDownEvent(position: Offset(100, 100)),
      );
      expect(container.read(textToolProvider).isNewText, isTrue);
      state.finishTextEditing();

      expect(container.read(textToolProvider).isEditing, isFalse);
      expect(texts(), isEmpty);
      expect(undoCount(), before);

      // Overlay path (focus lost / submitted with empty text).
      container.read(textToolProvider.notifier).startNewText(100, 100);
      expect(container.read(textToolProvider).isEditing, isTrue);
      expect(container.read(textToolProvider).isNewText, isTrue);
      state.handleTextEmptied();
      expect(container.read(textToolProvider).isEditing, isFalse);
      expect(texts(), isEmpty);
      expect(undoCount(), before);
    });

    testWidgets('non-empty edit still updates the text', (tester) async {
      await pump(tester);
      final original = addExistingText();

      editTo(original, 'World');
      state.finishTextEditing();

      expect(texts().single.text, 'World');
    });
  });
}
