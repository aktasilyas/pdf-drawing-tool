import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/internal.dart';

void main() {
  group('TextInputOverlay', () {
    late TextElement testText;

    setUp(() {
      testText = TextElement.create(
        text: 'Hello',
        x: 100,
        y: 100,
        fontSize: 20,
      );
    });

    testWidgets('renders TextField', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TextInputOverlay(
                    textElement: testText,
                    zoom: 1.0,
                    canvasOffset: Offset.zero,
                    onTextChanged: (_) {},
                    onEditingComplete: () {},
                    onCancel: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays initial text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TextInputOverlay(
                    textElement: testText,
                    zoom: 1.0,
                    canvasOffset: Offset.zero,
                    onTextChanged: (_) {},
                    onEditingComplete: () {},
                    onCancel: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('calls onTextChanged when text changes', (tester) async {
      TextElement? changedText;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TextInputOverlay(
                    textElement: testText,
                    zoom: 1.0,
                    canvasOffset: Offset.zero,
                    onTextChanged: (t) => changedText = t,
                    onEditingComplete: () {},
                    onCancel: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.pump();

      expect(changedText?.text, equals('Hello World'));
    });

    testWidgets('respects zoom and offset', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TextInputOverlay(
                    textElement: testText,
                    zoom: 2.0,
                    canvasOffset: const Offset(50, 50),
                    onTextChanged: (_) {},
                    onEditingComplete: () {},
                    onCancel: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Should position at (100 * 2.0 + 50, 100 * 2.0 + 50) = (250, 250)
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.left, equals(250));
      expect(positioned.top, equals(250));
    });
  });

  group('TextToolProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is not editing', () {
      final state = container.read(textToolProvider);
      expect(state.isEditing, isFalse);
      expect(state.activeText, isNull);
    });

    test('startNewText creates text and sets editing', () {
      container.read(textToolProvider.notifier).startNewText(50, 100);

      final state = container.read(textToolProvider);
      expect(state.isEditing, isTrue);
      expect(state.activeText?.x, equals(50));
      expect(state.activeText?.y, equals(100));
      expect(state.isNewText, isTrue);
    });

    test('editExistingText sets existing text', () {
      final text = TextElement.create(text: 'Existing', x: 0, y: 0);
      container.read(textToolProvider.notifier).editExistingText(text);

      final state = container.read(textToolProvider);
      expect(state.isEditing, isTrue);
      expect(state.activeText?.text, equals('Existing'));
      expect(state.isNewText, isFalse);
    });

    test('updateText updates active text', () {
      container.read(textToolProvider.notifier).startNewText(0, 0);
      final updatedText =
          container.read(textToolProvider).activeText!.copyWith(text: 'Updated');
      container.read(textToolProvider.notifier).updateText(updatedText);

      final state = container.read(textToolProvider);
      expect(state.activeText?.text, equals('Updated'));
    });

    test('finishEditing returns text and clears state', () {
      container.read(textToolProvider.notifier).startNewText(0, 0);
      container.read(textToolProvider.notifier).updateText(
            container.read(textToolProvider).activeText!.copyWith(text: 'Final'),
          );

      final result = container.read(textToolProvider.notifier).finishEditing();

      expect(result?.text, equals('Final'));
      expect(container.read(textToolProvider).isEditing, isFalse);
    });

    test('cancelEditing clears state', () {
      container.read(textToolProvider.notifier).startNewText(0, 0);
      container.read(textToolProvider.notifier).cancelEditing();

      expect(container.read(textToolProvider).isEditing, isFalse);
      expect(container.read(textToolProvider).activeText, isNull);
    });
  });
}
