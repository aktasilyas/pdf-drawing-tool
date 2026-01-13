import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('StrokeHitTester', () {
    late StrokeHitTester hitTester;

    setUp(() {
      hitTester = const StrokeHitTester();
    });

    group('hitTest', () {
      test('returns true when point is on horizontal line', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        expect(hitTester.hitTest(stroke, 50, 50, 5.0), isTrue);
      });

      test('returns true when point is on vertical line', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 50, y: 0))
            .addPoint(DrawingPoint(x: 50, y: 100));

        expect(hitTester.hitTest(stroke, 50, 50, 5.0), isTrue);
      });

      test('returns true when point is within tolerance', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        // 3 piksel yukarıda, tolerance 5
        expect(hitTester.hitTest(stroke, 50, 47, 5.0), isTrue);
      });

      test('returns false when point is outside tolerance', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        // 20 piksel yukarıda, tolerance 5, thickness 2 (effective: 6)
        expect(hitTester.hitTest(stroke, 50, 30, 5.0), isFalse);
      });

      test('accounts for stroke thickness', () {
        final thickStroke =
            Stroke.create(style: StrokeStyle.pen(thickness: 20.0))
                .addPoint(DrawingPoint(x: 0, y: 50))
                .addPoint(DrawingPoint(x: 100, y: 50));

        // 12 piksel yukarıda (y=38), tolerance 5, thickness/2 = 10
        // effective tolerance = 15, mesafe = 12 < 15 = HIT
        expect(hitTester.hitTest(thickStroke, 50, 38, 5.0), isTrue);
      });

      test('handles single point stroke', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 50, y: 50));

        expect(hitTester.hitTest(stroke, 50, 50, 5.0), isTrue);
        expect(hitTester.hitTest(stroke, 60, 50, 5.0), isFalse);
      });

      test('handles empty stroke', () {
        final stroke = Stroke.create(style: StrokeStyle.pen());

        expect(hitTester.hitTest(stroke, 50, 50, 5.0), isFalse);
      });

      test('handles diagonal line', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 0))
            .addPoint(DrawingPoint(x: 100, y: 100));

        // Çizgi üzerinde (50, 50)
        expect(hitTester.hitTest(stroke, 50, 50, 5.0), isTrue);

        // Çizgiden uzakta (0, 100) - mesafe ~70.7
        expect(hitTester.hitTest(stroke, 0, 100, 5.0), isFalse);
      });

      test('handles curved path (multi-point)', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 0))
            .addPoint(DrawingPoint(x: 50, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 0));

        // İlk segment üzerinde
        expect(hitTester.hitTest(stroke, 25, 25, 5.0), isTrue);

        // İkinci segment üzerinde
        expect(hitTester.hitTest(stroke, 75, 25, 5.0), isTrue);

        // Dışarıda
        expect(hitTester.hitTest(stroke, 50, 100, 5.0), isFalse);
      });

      test('handles point at segment endpoint', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 0))
            .addPoint(DrawingPoint(x: 100, y: 0));

        // Başlangıç noktasında
        expect(hitTester.hitTest(stroke, 0, 0, 5.0), isTrue);

        // Bitiş noktasında
        expect(hitTester.hitTest(stroke, 100, 0, 5.0), isTrue);
      });

      test('handles point beyond segment (projection clamping)', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 20, y: 50))
            .addPoint(DrawingPoint(x: 80, y: 50));

        // Segment'in solunda (x=10) - en yakın nokta (20, 50)
        // Mesafe = 10, tolerance + thickness/2 = 6, 10 > 6 = MISS
        expect(hitTester.hitTest(stroke, 10, 50, 5.0), isFalse);

        // Segment'in sağında (x=90) - en yakın nokta (80, 50)
        expect(hitTester.hitTest(stroke, 90, 50, 5.0), isFalse);
      });
    });

    group('findTopElementAt', () {
      test('returns last drawn stroke (topmost)', () {
        final stroke1 = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        final stroke2 = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 50, y: 0))
            .addPoint(DrawingPoint(x: 50, y: 100));

        final strokes = [stroke1, stroke2];

        // Kesişim noktasında (50, 50) - stroke2 en üstte
        final result = hitTester.findTopElementAt(strokes, 50, 50, 5.0);
        expect(result, equals(stroke2));
      });

      test('returns null when no stroke at point', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 0))
            .addPoint(DrawingPoint(x: 10, y: 10));

        final result = hitTester.findTopElementAt([stroke], 100, 100, 5.0);
        expect(result, isNull);
      });

      test('handles empty strokes list', () {
        final result = hitTester.findTopElementAt([], 50, 50, 5.0);
        expect(result, isNull);
      });

      test('returns only stroke when single match', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        final result = hitTester.findTopElementAt([stroke], 50, 50, 5.0);
        expect(result, equals(stroke));
      });
    });

    group('findElementsAt', () {
      test('returns all strokes at point', () {
        final stroke1 = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        final stroke2 = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 50, y: 0))
            .addPoint(DrawingPoint(x: 50, y: 100));

        final stroke3 = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 200, y: 200))
            .addPoint(DrawingPoint(x: 300, y: 300));

        final strokes = [stroke1, stroke2, stroke3];

        final result = hitTester.findElementsAt(strokes, 50, 50, 5.0);
        expect(result.length, equals(2));
        expect(result, contains(stroke1));
        expect(result, contains(stroke2));
      });

      test('returns empty list when no strokes at point', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 0))
            .addPoint(DrawingPoint(x: 10, y: 10));

        final result = hitTester.findElementsAt([stroke], 100, 100, 5.0);
        expect(result, isEmpty);
      });

      test('handles empty strokes list', () {
        final result = hitTester.findElementsAt([], 50, 50, 5.0);
        expect(result, isEmpty);
      });
    });

    group('performance - bounds check', () {
      test('bounds check eliminates far strokes quickly', () {
        // Bu test bounding box pre-filter'ın çalıştığını doğrular
        final farStroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 1000, y: 1000))
            .addPoint(DrawingPoint(x: 1100, y: 1100));

        // Çok uzakta - bounds check'te elenmeli
        expect(hitTester.hitTest(farStroke, 0, 0, 5.0), isFalse);
      });

      test('bounds check includes stroke thickness', () {
        final thickStroke =
            Stroke.create(style: StrokeStyle.pen(thickness: 50.0))
                .addPoint(DrawingPoint(x: 100, y: 100))
                .addPoint(DrawingPoint(x: 200, y: 100));

        // bounds: 100-200, thickness/2 = 25, tolerance = 5
        // effective bounds: 70-230 (100-30 to 200+30)
        // x=75, y=100 => bounds check'ten geçmeli ve hit olmalı
        expect(hitTester.hitTest(thickStroke, 75, 100, 5.0), isTrue);
      });
    });

    group('edge cases', () {
      test('handles zero-length segment (same start and end point)', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 50, y: 50))
            .addPoint(DrawingPoint(x: 50, y: 50)); // Same point

        expect(hitTester.hitTest(stroke, 50, 50, 5.0), isTrue);
        expect(hitTester.hitTest(stroke, 60, 50, 5.0), isFalse);
      });

      test('handles very small tolerance', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        // Tam çizgi üzerinde - küçük tolerance ile bile hit olmalı
        expect(hitTester.hitTest(stroke, 50, 50, 0.1), isTrue);
      });

      test('handles large tolerance', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: 0, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 50));

        // 40 piksel uzakta, ama tolerance 50
        expect(hitTester.hitTest(stroke, 50, 10, 50.0), isTrue);
      });

      test('handles negative coordinates', () {
        final stroke = Stroke.create(style: StrokeStyle.pen(thickness: 2.0))
            .addPoint(DrawingPoint(x: -100, y: -50))
            .addPoint(DrawingPoint(x: 0, y: -50));

        expect(hitTester.hitTest(stroke, -50, -50, 5.0), isTrue);
      });
    });
  });
}
