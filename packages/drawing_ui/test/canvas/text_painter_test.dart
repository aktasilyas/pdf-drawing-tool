import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/internal.dart';

void main() {
  group('TextElementPainter', () {
    test('creates without error', () {
      final painter = TextElementPainter(texts: []);
      expect(painter, isNotNull);
    });

    test('shouldRepaint returns true when texts change', () {
      final text1 =
          const TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
      final text2 =
          const TextElement(id: 'text-2', text: 'World', x: 100, y: 100);

      final painter1 = TextElementPainter(texts: [text1]);
      final painter2 = TextElementPainter(texts: [text1, text2]);

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('shouldRepaint returns false when texts are same', () {
      final texts = [
        const TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0),
      ];

      final painter1 = TextElementPainter(texts: texts);
      final painter2 = TextElementPainter(texts: texts);

      expect(painter2.shouldRepaint(painter1), isFalse);
    });

    test('shouldRepaint returns true when activeText changes', () {
      final text =
          const TextElement(id: 'text-1', text: 'Active', x: 0, y: 0);

      final painter1 = TextElementPainter(texts: [], activeText: null);
      final painter2 = TextElementPainter(texts: [], activeText: text);

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('shouldRepaint returns true when showCursor changes', () {
      final painter1 = TextElementPainter(texts: [], showCursor: false);
      final painter2 = TextElementPainter(texts: [], showCursor: true);

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    testWidgets('renders without error in CustomPaint', (tester) async {
      final text = TextElement.create(
        text: 'Hello World',
        x: 10,
        y: 10,
        fontSize: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: TextElementPainter(texts: [text]),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders text with different styles', (tester) async {
      final texts = [
        TextElement.create(
          text: 'Bold',
          x: 10,
          y: 10,
          isBold: true,
        ),
        TextElement.create(
          text: 'Italic',
          x: 10,
          y: 40,
          isItalic: true,
        ),
        TextElement.create(
          text: 'Underline',
          x: 10,
          y: 70,
          isUnderline: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: TextElementPainter(texts: texts),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders active text with editing indicator', (tester) async {
      final activeText = TextElement.create(
        text: 'Editing',
        x: 50,
        y: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: TextElementPainter(
                texts: [],
                activeText: activeText,
                showCursor: true,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders text with different alignments', (tester) async {
      final texts = [
        TextElement.create(
          text: 'Left aligned',
          x: 10,
          y: 10,
          alignment: TextAlignment.left,
        ),
        TextElement.create(
          text: 'Center aligned',
          x: 10,
          y: 40,
          alignment: TextAlignment.center,
        ),
        TextElement.create(
          text: 'Right aligned',
          x: 10,
          y: 70,
          alignment: TextAlignment.right,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: TextElementPainter(texts: texts),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
