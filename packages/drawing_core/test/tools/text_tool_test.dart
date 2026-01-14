import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('TextTool', () {
    late TextTool textTool;

    setUp(() {
      textTool = TextTool(
        defaultFontSize: 20.0,
        defaultColor: 0xFF0000FF,
      );
    });

    group('startText', () {
      test('creates new text element at position', () {
        final text = textTool.startText(100, 200);

        expect(text.x, equals(100));
        expect(text.y, equals(200));
        expect(text.text, isEmpty);
        expect(text.fontSize, equals(20.0));
        expect(text.color, equals(0xFF0000FF));
      });

      test('sets editing mode', () {
        textTool.startText(0, 0);
        expect(textTool.isEditing, isTrue);
      });

      test('sets activeText', () {
        textTool.startText(50, 100);
        expect(textTool.activeText, isNotNull);
        expect(textTool.activeText?.x, equals(50));
      });
    });

    group('updateText', () {
      test('updates active text content', () {
        textTool.startText(0, 0);
        final updated = textTool.updateText('Hello World');

        expect(updated?.text, equals('Hello World'));
        expect(textTool.activeText?.text, equals('Hello World'));
      });

      test('returns null when no active text', () {
        final result = textTool.updateText('Test');
        expect(result, isNull);
      });
    });

    group('updateStyle', () {
      test('updates text style', () {
        textTool.startText(0, 0);
        final updated = textTool.updateStyle(
          fontSize: 32,
          isBold: true,
          alignment: TextAlignment.center,
        );

        expect(updated?.fontSize, equals(32));
        expect(updated?.isBold, isTrue);
        expect(updated?.alignment, equals(TextAlignment.center));
      });

      test('returns null when no active text', () {
        final result = textTool.updateStyle(fontSize: 24);
        expect(result, isNull);
      });

      test('preserves unchanged style properties', () {
        textTool.startText(0, 0);
        textTool.updateStyle(isBold: true);
        final updated = textTool.updateStyle(isItalic: true);

        expect(updated?.isBold, isTrue);
        expect(updated?.isItalic, isTrue);
      });
    });

    group('endText', () {
      test('returns text and clears state', () {
        textTool.startText(0, 0);
        textTool.updateText('Final text');

        final result = textTool.endText();

        expect(result?.text, equals('Final text'));
        expect(textTool.isEditing, isFalse);
        expect(textTool.activeText, isNull);
      });

      test('returns null for empty text', () {
        textTool.startText(0, 0);
        textTool.updateText('   ');

        final result = textTool.endText();

        expect(result, isNull);
      });

      test('returns null when not editing', () {
        final result = textTool.endText();
        expect(result, isNull);
      });
    });

    group('cancelText', () {
      test('clears state without returning text', () {
        textTool.startText(0, 0);
        textTool.updateText('Some text');
        textTool.cancelText();

        expect(textTool.isEditing, isFalse);
        expect(textTool.activeText, isNull);
      });
    });

    group('editText', () {
      test('allows editing existing text', () {
        final existingText = TextElement.create(
          text: 'Existing',
          x: 50,
          y: 50,
        );

        textTool.editText(existingText);

        expect(textTool.isEditing, isTrue);
        expect(textTool.activeText?.text, equals('Existing'));
      });

      test('can update edited text', () {
        final existingText = TextElement.create(
          text: 'Existing',
          x: 50,
          y: 50,
        );

        textTool.editText(existingText);
        textTool.updateText('Modified');

        expect(textTool.activeText?.text, equals('Modified'));
        expect(textTool.activeText?.id, equals(existingText.id));
      });
    });

    group('default values', () {
      test('uses default values when not specified', () {
        final defaultTool = TextTool();
        final text = defaultTool.startText(0, 0);

        expect(text.fontSize, equals(16.0));
        expect(text.color, equals(0xFF000000));
        expect(text.fontFamily, equals('Roboto'));
      });
    });
  });
}
