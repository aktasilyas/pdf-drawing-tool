import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

// Test için concrete implementation
class TestHitTester extends HitTester<String> {
  @override
  bool hitTest(String element, double x, double y, double tolerance) {
    // Simple test: element 'hit' içeriyorsa true
    return element.contains('hit');
  }

  @override
  List<String> findElementsAt(
    List<String> elements,
    double x,
    double y,
    double tolerance,
  ) {
    return elements.where((e) => hitTest(e, x, y, tolerance)).toList();
  }

  @override
  String? findTopElementAt(
    List<String> elements,
    double x,
    double y,
    double tolerance,
  ) {
    // Tersten tara (son çizilen en üstte)
    for (int i = elements.length - 1; i >= 0; i--) {
      if (hitTest(elements[i], x, y, tolerance)) {
        return elements[i];
      }
    }
    return null;
  }
}

void main() {
  group('HitTester', () {
    test('HitTester abstract class exists and can be extended', () {
      final tester = TestHitTester();
      expect(tester, isA<HitTester<String>>());
    });

    test('hitTest returns true for matching element', () {
      final tester = TestHitTester();
      expect(tester.hitTest('hit_element', 0, 0, 10), isTrue);
    });

    test('hitTest returns false for non-matching element', () {
      final tester = TestHitTester();
      expect(tester.hitTest('miss_element', 0, 0, 10), isFalse);
    });

    test('findElementsAt returns all matching elements', () {
      final tester = TestHitTester();
      final elements = ['hit_1', 'miss_1', 'hit_2', 'miss_2'];

      final results = tester.findElementsAt(elements, 0, 0, 10);

      expect(results, hasLength(2));
      expect(results, contains('hit_1'));
      expect(results, contains('hit_2'));
    });

    test('findElementsAt returns empty list when no matches', () {
      final tester = TestHitTester();
      final elements = ['miss_1', 'miss_2'];

      final results = tester.findElementsAt(elements, 0, 0, 10);

      expect(results, isEmpty);
    });

    test('findTopElementAt returns last matching element (top-most)', () {
      final tester = TestHitTester();
      final elements = ['hit_first', 'miss', 'hit_last'];

      final result = tester.findTopElementAt(elements, 0, 0, 10);

      expect(result, equals('hit_last'));
    });

    test('findTopElementAt returns null when no matches', () {
      final tester = TestHitTester();
      final elements = ['miss_1', 'miss_2'];

      final result = tester.findTopElementAt(elements, 0, 0, 10);

      expect(result, isNull);
    });

    test('findTopElementAt returns single element when only one matches', () {
      final tester = TestHitTester();
      final elements = ['miss_1', 'hit_only', 'miss_2'];

      final result = tester.findTopElementAt(elements, 0, 0, 10);

      expect(result, equals('hit_only'));
    });

    test('findTopElementAt handles empty list', () {
      final tester = TestHitTester();
      final elements = <String>[];

      final result = tester.findTopElementAt(elements, 0, 0, 10);

      expect(result, isNull);
    });
  });
}
