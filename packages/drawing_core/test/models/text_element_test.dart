import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('TextElement', () {
    group('creation', () {
      test('factory creates with valid id', () {
        final text = TextElement.create(
          text: 'Hello',
          x: 0,
          y: 0,
        );

        expect(text.id, isNotEmpty);
        expect(text.id, isA<String>());
        expect(int.tryParse(text.id), isNotNull);
      });

      test('default values are set correctly', () {
        final text = TextElement.create(
          text: 'Test',
          x: 50,
          y: 50,
        );

        expect(text.fontSize, equals(16.0));
        expect(text.color, equals(0xFF000000));
        expect(text.isBold, isFalse);
        expect(text.isItalic, isFalse);
        expect(text.isUnderline, isFalse);
        expect(text.alignment, equals(TextAlignment.left));
        expect(text.fontFamily, equals('Roboto'));
      });
    });

    group('properties', () {
      test('x and y return correct values', () {
        final text = TextElement.create(
          text: 'Test',
          x: 25,
          y: 75,
        );

        expect(text.x, equals(25));
        expect(text.y, equals(75));
      });

      test('isEmpty and isNotEmpty work correctly', () {
        final emptyText = TextElement.create(text: '', x: 0, y: 0);
        final nonEmptyText = TextElement.create(text: 'Hello', x: 0, y: 0);

        expect(emptyText.isEmpty, isTrue);
        expect(emptyText.isNotEmpty, isFalse);
        expect(nonEmptyText.isEmpty, isFalse);
        expect(nonEmptyText.isNotEmpty, isTrue);
      });

      test('bounds calculated correctly', () {
        final text = TextElement.create(
          text: 'Hello',
          x: 10,
          y: 20,
          fontSize: 20,
        );

        final bounds = text.bounds;

        expect(bounds.left, equals(10));
        expect(bounds.top, equals(20));
        expect(bounds.right, greaterThan(10));
        expect(bounds.bottom, greaterThan(20));
      });

      test('multiline text bounds calculated correctly', () {
        final text = TextElement.create(
          text: 'Line 1\nLine 2\nLine 3',
          x: 0,
          y: 0,
          fontSize: 16,
        );

        final bounds = text.bounds;

        // 3 lines * 1.2 line height * 16 fontSize = 57.6
        expect(bounds.bottom, greaterThanOrEqualTo(57));
      });
    });

    group('hit testing', () {
      test('containsPoint returns true inside bounds', () {
        final text = TextElement.create(
          text: 'Hello World',
          x: 0,
          y: 0,
          fontSize: 20,
        );

        expect(text.containsPoint(10, 10, 5), isTrue);
      });

      test('containsPoint returns false outside bounds', () {
        final text = TextElement.create(
          text: 'Hi',
          x: 0,
          y: 0,
          fontSize: 16,
        );

        expect(text.containsPoint(500, 500, 5), isFalse);
      });

      test('containsPoint respects tolerance', () {
        final text = TextElement.create(
          text: 'Test',
          x: 100,
          y: 100,
          fontSize: 16,
        );

        // Just outside bounds but within tolerance
        expect(text.containsPoint(98, 100, 5), isTrue);
        // Far outside bounds
        expect(text.containsPoint(50, 50, 5), isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated values', () {
        final text = TextElement.create(
          text: 'Original',
          x: 0,
          y: 0,
        );

        final updated = text.copyWith(
          text: 'Updated',
          fontSize: 24,
          isBold: true,
        );

        expect(updated.id, equals(text.id));
        expect(updated.text, equals('Updated'));
        expect(updated.fontSize, equals(24));
        expect(updated.isBold, isTrue);
        // Unchanged values
        expect(updated.x, equals(0));
        expect(updated.y, equals(0));
        expect(updated.isItalic, isFalse);
      });

      test('preserves id on copy', () {
        final text = TextElement.create(
          text: 'Test',
          x: 10,
          y: 20,
        );

        final updated = text.copyWith(x: 100, y: 200);

        expect(updated.id, equals(text.id));
      });
    });

    group('serialization', () {
      test('toJson and fromJson roundtrip', () {
        final text = TextElement.create(
          text: 'Hello World',
          x: 100,
          y: 200,
          fontSize: 24,
          color: 0xFFFF0000,
          fontFamily: 'Arial',
          isBold: true,
          isItalic: true,
          isUnderline: true,
          alignment: TextAlignment.center,
          width: 200,
          height: 50,
        );

        final json = text.toJson();
        final restored = TextElement.fromJson(json);

        expect(restored.id, equals(text.id));
        expect(restored.text, equals(text.text));
        expect(restored.x, equals(text.x));
        expect(restored.y, equals(text.y));
        expect(restored.fontSize, equals(text.fontSize));
        expect(restored.color, equals(text.color));
        expect(restored.fontFamily, equals(text.fontFamily));
        expect(restored.isBold, equals(text.isBold));
        expect(restored.isItalic, equals(text.isItalic));
        expect(restored.isUnderline, equals(text.isUnderline));
        expect(restored.alignment, equals(text.alignment));
        expect(restored.width, equals(text.width));
        expect(restored.height, equals(text.height));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': '123',
          'text': 'Test',
          'x': 10,
          'y': 20,
        };

        final text = TextElement.fromJson(json);

        expect(text.fontSize, equals(16.0));
        expect(text.color, equals(0xFF000000));
        expect(text.fontFamily, equals('Roboto'));
        expect(text.isBold, isFalse);
        expect(text.alignment, equals(TextAlignment.left));
      });
    });

    group('equality', () {
      test('equal when same id', () {
        final text1 = TextElement(
          id: 'same-id',
          text: 'Hello',
          x: 0,
          y: 0,
        );

        final text2 = TextElement(
          id: 'same-id',
          text: 'Different text',
          x: 100,
          y: 100,
        );

        expect(text1 == text2, isTrue);
        expect(text1.hashCode, equals(text2.hashCode));
      });

      test('not equal when different id', () {
        final text1 = TextElement(
          id: 'id-1',
          text: 'Hello',
          x: 0,
          y: 0,
        );

        final text2 = TextElement(
          id: 'id-2',
          text: 'Hello',
          x: 0,
          y: 0,
        );

        expect(text1 == text2, isFalse);
      });
    });
  });

  group('TextAlignment', () {
    test('has all expected values', () {
      expect(TextAlignment.values, contains(TextAlignment.left));
      expect(TextAlignment.values, contains(TextAlignment.center));
      expect(TextAlignment.values, contains(TextAlignment.right));
      expect(TextAlignment.values.length, equals(3));
    });
  });
}
