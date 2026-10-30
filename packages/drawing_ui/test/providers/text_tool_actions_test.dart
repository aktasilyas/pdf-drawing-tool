import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// Committing the text being typed from outside the canvas (#489).
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  TextToolActions actions() => container.read(textToolActionsProvider);
  TextToolNotifier tool() => container.read(textToolProvider.notifier);
  List<TextElement> texts() =>
      container.read(documentProvider).layers.first.texts;
  int undoCount() => container.read(historyManagerProvider).undoCount;

  void type(String value) {
    tool().startNewText(10, 20, layerIndex: 0);
    final active = container.read(textToolProvider).activeText!;
    tool().updateText(active.copyWith(text: value));
  }

  group('TextToolActions.commit', () {
    test('adds a new text in one undo step and ends editing', () {
      type('Hello');

      final added = actions().commit();

      expect(added?.text, 'Hello');
      expect(texts().map((t) => t.text), ['Hello']);
      expect(undoCount(), 1);
      expect(container.read(textToolProvider).isEditing, isFalse);
    });

    test('an empty new text box creates nothing', () {
      type('   ');

      expect(actions().commit(), isNull);

      expect(texts(), isEmpty);
      expect(undoCount(), 0);
      expect(container.read(textToolProvider).isEditing, isFalse);
    });

    test('does nothing when no text is being edited', () {
      expect(actions().commit(), isNull);
      expect(undoCount(), 0);
    });

    test('updates an edited existing text', () {
      type('Hello');
      final added = actions().commit()!;
      tool().editExistingText(added, layerIndex: 0);
      tool().updateText(added.copyWith(text: 'Hello world'));

      expect(actions().commit(), isNull);

      expect(texts().map((t) => t.text), ['Hello world']);
      expect(undoCount(), 2);
    });

    test('emptying an existing text removes it; undo restores it', () {
      type('Hello');
      final added = actions().commit()!;
      tool().editExistingText(added, layerIndex: 0);
      tool().updateText(added.copyWith(text: ''));

      actions().commit();
      expect(texts(), isEmpty);

      container.read(historyManagerProvider.notifier).undo();
      expect(texts().map((t) => t.text), ['Hello']);
    });
  });
}
