import 'package:test/test.dart';
import 'package:drawing_core/src/models/bounding_box.dart';

void main() {
  group('BoundingBox', () {
    group('Constructor', () {
      test('creates with required parameters', () {
        final box = BoundingBox(left: 10, top: 20, right: 100, bottom: 80);

        expect(box.left, 10);
        expect(box.top, 20);
        expect(box.right, 100);
        expect(box.bottom, 80);
      });

      test('fromPoint creates box at single point', () {
        final box = BoundingBox.fromPoint(50, 60);

        expect(box.left, 50);
        expect(box.top, 60);
        expect(box.right, 50);
        expect(box.bottom, 60);
        expect(box.width, 0);
        expect(box.height, 0);
      });

      test('zero creates box at origin', () {
        final box = BoundingBox.zero();

        expect(box.left, 0);
        expect(box.top, 0);
        expect(box.right, 0);
        expect(box.bottom, 0);
      });
    });

    group('Getters', () {
      test('width returns correct value', () {
        final box = BoundingBox(left: 10, top: 20, right: 100, bottom: 80);
        expect(box.width, 90);
      });

      test('height returns correct value', () {
        final box = BoundingBox(left: 10, top: 20, right: 100, bottom: 80);
        expect(box.height, 60);
      });

      test('centerX returns correct value', () {
        final box = BoundingBox(left: 10, top: 20, right: 100, bottom: 80);
        expect(box.centerX, 55);
      });

      test('centerY returns correct value', () {
        final box = BoundingBox(left: 10, top: 20, right: 100, bottom: 80);
        expect(box.centerY, 50);
      });

      test('isEmpty returns true for zero-size box', () {
        final box = BoundingBox.fromPoint(50, 50);
        expect(box.isEmpty, true);
      });

      test('isEmpty returns false for non-zero box', () {
        final box = BoundingBox(left: 0, top: 0, right: 10, bottom: 10);
        expect(box.isEmpty, false);
      });
    });

    group('contains', () {
      test('returns true for point inside box', () {
        final box = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);
        expect(box.contains(50, 50), true);
      });

      test('returns true for point on edge', () {
        final box = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);
        expect(box.contains(0, 50), true);
        expect(box.contains(100, 50), true);
        expect(box.contains(50, 0), true);
        expect(box.contains(50, 100), true);
      });

      test('returns true for point on corner', () {
        final box = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);
        expect(box.contains(0, 0), true);
        expect(box.contains(100, 100), true);
      });

      test('returns false for point outside box', () {
        final box = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);
        expect(box.contains(-1, 50), false);
        expect(box.contains(101, 50), false);
        expect(box.contains(50, -1), false);
        expect(box.contains(50, 101), false);
      });
    });

    group('expandTo', () {
      test('expands to include point outside', () {
        final box = BoundingBox(left: 10, top: 10, right: 20, bottom: 20);
        final expanded = box.expandTo(5, 5);

        expect(expanded.left, 5);
        expect(expanded.top, 5);
        expect(expanded.right, 20);
        expect(expanded.bottom, 20);
      });

      test('expands in all directions', () {
        final box = BoundingBox(left: 10, top: 10, right: 20, bottom: 20);
        final expanded = box.expandTo(25, 25);

        expect(expanded.right, 25);
        expect(expanded.bottom, 25);
      });

      test('does not shrink for point inside', () {
        final box = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);
        final expanded = box.expandTo(50, 50);

        expect(expanded, equals(box));
      });
    });

    group('union', () {
      test('combines two non-overlapping boxes', () {
        final box1 = BoundingBox(left: 0, top: 0, right: 10, bottom: 10);
        final box2 = BoundingBox(left: 20, top: 20, right: 30, bottom: 30);
        final united = box1.union(box2);

        expect(united.left, 0);
        expect(united.top, 0);
        expect(united.right, 30);
        expect(united.bottom, 30);
      });

      test('combines overlapping boxes', () {
        final box1 = BoundingBox(left: 0, top: 0, right: 20, bottom: 20);
        final box2 = BoundingBox(left: 10, top: 10, right: 30, bottom: 30);
        final united = box1.union(box2);

        expect(united.left, 0);
        expect(united.top, 0);
        expect(united.right, 30);
        expect(united.bottom, 30);
      });
    });

    group('inflate', () {
      test('inflates box by positive delta', () {
        final box = BoundingBox(left: 10, top: 10, right: 20, bottom: 20);
        final inflated = box.inflate(5);

        expect(inflated.left, 5);
        expect(inflated.top, 5);
        expect(inflated.right, 25);
        expect(inflated.bottom, 25);
      });

      test('deflates box by negative delta', () {
        final box = BoundingBox(left: 10, top: 10, right: 30, bottom: 30);
        final deflated = box.inflate(-5);

        expect(deflated.left, 15);
        expect(deflated.top, 15);
        expect(deflated.right, 25);
        expect(deflated.bottom, 25);
      });
    });

    group('copyWith', () {
      test('copies with single parameter changed', () {
        final box = BoundingBox(left: 10, top: 20, right: 30, bottom: 40);
        final copied = box.copyWith(left: 5);

        expect(copied.left, 5);
        expect(copied.top, 20);
        expect(copied.right, 30);
        expect(copied.bottom, 40);
      });

      test('copies with all parameters changed', () {
        final box = BoundingBox(left: 10, top: 20, right: 30, bottom: 40);
        final copied = box.copyWith(left: 1, top: 2, right: 3, bottom: 4);

        expect(copied.left, 1);
        expect(copied.top, 2);
        expect(copied.right, 3);
        expect(copied.bottom, 4);
      });
    });

    group('Equality', () {
      test('two boxes with same values are equal', () {
        final box1 = BoundingBox(left: 10, top: 20, right: 30, bottom: 40);
        final box2 = BoundingBox(left: 10, top: 20, right: 30, bottom: 40);

        expect(box1, equals(box2));
        expect(box1.hashCode, equals(box2.hashCode));
      });

      test('two boxes with different values are not equal', () {
        final box1 = BoundingBox(left: 10, top: 20, right: 30, bottom: 40);
        final box2 = BoundingBox(left: 10, top: 20, right: 30, bottom: 50);

        expect(box1, isNot(equals(box2)));
      });
    });

    group('JSON serialization', () {
      test('toJson converts to correct map', () {
        final box = BoundingBox(left: 10, top: 20, right: 30, bottom: 40);
        final json = box.toJson();

        expect(json, {
          'left': 10.0,
          'top': 20.0,
          'right': 30.0,
          'bottom': 40.0,
        });
      });

      test('fromJson creates correct box', () {
        final json = {
          'left': 10.0,
          'top': 20.0,
          'right': 30.0,
          'bottom': 40.0,
        };
        final box = BoundingBox.fromJson(json);

        expect(box.left, 10);
        expect(box.top, 20);
        expect(box.right, 30);
        expect(box.bottom, 40);
      });

      test('roundtrip preserves values', () {
        final original = BoundingBox(left: 10.5, top: 20.5, right: 30.5, bottom: 40.5);
        final restored = BoundingBox.fromJson(original.toJson());

        expect(restored, equals(original));
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        final box = BoundingBox(left: 10, top: 20, right: 30, bottom: 40);
        expect(box.toString(), 'BoundingBox(left: 10.0, top: 20.0, right: 30.0, bottom: 40.0)');
      });
    });
  });
}
