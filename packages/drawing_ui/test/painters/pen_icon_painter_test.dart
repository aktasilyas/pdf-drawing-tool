import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/painters/pen_icons/pen_icons.dart';

void main() {
  group('PenIconPainter shouldRepaint', () {
    test('returns true when penColor changes', () {
      const painter1 = PencilIconPainter(penColor: Colors.black);
      const painter2 = PencilIconPainter(penColor: Colors.red);

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('returns true when isSelected changes', () {
      const painter1 = PencilIconPainter(isSelected: false);
      const painter2 = PencilIconPainter(isSelected: true);

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('returns true when size changes', () {
      const painter1 = PencilIconPainter(size: 56.0);
      const painter2 = PencilIconPainter(size: 100.0);

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('returns false when properties are same', () {
      const painter1 = PencilIconPainter(penColor: Colors.black);
      const painter2 = PencilIconPainter(penColor: Colors.black);

      expect(painter2.shouldRepaint(painter1), isFalse);
    });
  });

  group('All painters instantiate correctly', () {
    test('PencilIconPainter has default size', () {
      const painter = PencilIconPainter();
      expect(painter.size, 56.0);
    });

    test('HardPencilIconPainter has default size', () {
      const painter = HardPencilIconPainter();
      expect(painter.size, 56.0);
    });

    test('BallpointIconPainter has default size', () {
      const painter = BallpointIconPainter();
      expect(painter.size, 56.0);
    });

    test('GelPenIconPainter has default size', () {
      const painter = GelPenIconPainter();
      expect(painter.size, 56.0);
    });

    test('DashedPenIconPainter has default size', () {
      const painter = DashedPenIconPainter();
      expect(painter.size, 56.0);
    });

    test('HighlighterIconPainter has default size', () {
      const painter = HighlighterIconPainter();
      expect(painter.size, 56.0);
    });

    test('BrushPenIconPainter has default size', () {
      const painter = BrushPenIconPainter();
      expect(painter.size, 56.0);
    });

    test('MarkerIconPainter has default size', () {
      const painter = MarkerIconPainter();
      expect(painter.size, 56.0);
    });

    test('NeonHighlighterIconPainter has default size', () {
      const painter = NeonHighlighterIconPainter();
      expect(painter.size, 56.0);
    });

    test('RulerPenIconPainter has default size', () {
      const painter = RulerPenIconPainter();
      expect(painter.size, 56.0);
    });
  });

  group('Painters accept custom parameters', () {
    test('PencilIconPainter accepts custom color', () {
      const painter = PencilIconPainter(penColor: Colors.blue);
      expect(painter.penColor, Colors.blue);
    });

    test('HighlighterIconPainter accepts custom color', () {
      const painter = HighlighterIconPainter(penColor: Colors.yellow);
      expect(painter.penColor, Colors.yellow);
    });

    test('NeonHighlighterIconPainter accepts custom color', () {
      const painter = NeonHighlighterIconPainter(penColor: Colors.green);
      expect(painter.penColor, Colors.green);
    });

    test('MarkerIconPainter accepts isSelected', () {
      const painter = MarkerIconPainter(isSelected: true);
      expect(painter.isSelected, isTrue);
    });

    test('BrushPenIconPainter accepts custom size', () {
      const painter = BrushPenIconPainter(size: 80.0);
      expect(painter.size, 80.0);
    });
  });
}
