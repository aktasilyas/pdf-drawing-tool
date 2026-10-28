import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

/// A text element as written by drawing_core before the split (#340).
/// Stored notebooks contain this exact format; it must keep decoding.
const _storedTextJson = '''
{
  "id": "text-1",
  "text": "Merhaba\\nWorld",
  "x": 12.5,
  "y": 40.0,
  "fontSize": 24.0,
  "color": 4293212469,
  "fontFamily": "Inter",
  "isBold": true,
  "isItalic": true,
  "isUnderline": true,
  "alignment": "center",
  "width": 200.0,
  "height": 80.5,
  "rotation": 0.25
}
''';

TextElement _roundTrip(TextElement element) {
  final encoded = jsonEncode(element.toJson());
  return TextElement.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}

void main() {
  group('TextElement JSON', () {
    test('round-trips every optional field', () {
      const element = TextElement(
        id: 'text-full',
        text: 'Line one\nLine two 😀',
        x: 12.5,
        y: 40,
        fontSize: 24,
        color: 0xFFE53935,
        fontFamily: 'Inter',
        isBold: true,
        isItalic: true,
        isUnderline: true,
        alignment: TextAlignment.right,
        width: 200,
        height: 80.5,
        rotation: 0.25,
      );

      expect(_roundTrip(element), equals(element));
    });

    test('round-trips defaults with null width and height', () {
      const element = TextElement(id: 'text-min', text: 'Hi', x: 0, y: 0);
      final restored = _roundTrip(element);

      expect(restored, equals(element));
      expect(restored.width, isNull);
      expect(restored.height, isNull);
    });

    for (final alignment in TextAlignment.values) {
      test('round-trips alignment ${alignment.name}', () {
        final element = TextElement(
          id: 'text-${alignment.name}',
          text: 'a',
          x: 1,
          y: 2,
          alignment: alignment,
        );
        expect(_roundTrip(element).alignment, alignment);
      });
    }

    test('toJson writes the stored key set', () {
      const element = TextElement(id: 't', text: 'x', x: 0, y: 0);
      expect(
        element.toJson().keys,
        unorderedEquals([
          'id',
          'text',
          'x',
          'y',
          'fontSize',
          'color',
          'fontFamily',
          'isBold',
          'isItalic',
          'isUnderline',
          'alignment',
          'width',
          'height',
          'rotation',
        ]),
      );
    });

    test('decodes a text element stored by the previous version', () {
      final element = TextElement.fromJson(
        jsonDecode(_storedTextJson) as Map<String, dynamic>,
      );

      expect(
        element,
        const TextElement(
          id: 'text-1',
          text: 'Merhaba\nWorld',
          x: 12.5,
          y: 40,
          fontSize: 24,
          color: 0xFFE53935,
          fontFamily: 'Inter',
          isBold: true,
          isItalic: true,
          isUnderline: true,
          alignment: TextAlignment.center,
          width: 200,
          height: 80.5,
          rotation: 0.25,
        ),
      );
    });

    test('parses lenient numbers', () {
      final element = TextElement.fromJson({
        'id': 'text-lenient',
        'text': 'x',
        'x': 5,
        'y': '7.5',
        'fontSize': 18,
        'color': 255.0,
        'width': 100,
        'rotation': 'bad',
      });

      expect(element.x, 5.0);
      expect(element.y, 7.5);
      expect(element.fontSize, 18.0);
      expect(element.color, 255);
      expect(element.width, 100.0);
      expect(element.height, isNull);
      expect(element.rotation, 0.0);
      expect(element.alignment, TextAlignment.left);
      expect(element.fontFamily, 'Roboto');
    });
  });
}
