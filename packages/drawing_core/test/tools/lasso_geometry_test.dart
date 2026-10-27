import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_core/src/tools/lasso_geometry.dart';

DrawingPoint p(double x, double y) => DrawingPoint(x: x, y: y);

void main() {
  group('LassoGeometry.isPointInPolygon', () {
    final square = [p(0, 0), p(10, 0), p(10, 10), p(0, 10)];

    test('inside and outside a square', () {
      expect(LassoGeometry.isPointInPolygon(5, 5, square), isTrue);
      expect(LassoGeometry.isPointInPolygon(15, 5, square), isFalse);
    });

    test('concave polygon excludes the notch', () {
      final u = [
        p(0, 0),
        p(10, 0),
        p(10, 10),
        p(7, 10),
        p(7, 3),
        p(3, 3),
        p(3, 10),
        p(0, 10)
      ];
      expect(LassoGeometry.isPointInPolygon(5, 6, u), isFalse);
      expect(LassoGeometry.isPointInPolygon(1, 8, u), isTrue);
    });

    test('point on left edge is inside, on right edge is outside', () {
      expect(LassoGeometry.isPointInPolygon(0, 5, square), isTrue);
      expect(LassoGeometry.isPointInPolygon(10, 5, square), isFalse);
    });

    test('degenerate polygons are never inside', () {
      expect(LassoGeometry.isPointInPolygon(0, 0, [p(0, 0), p(1, 1)]), isFalse);
      expect(LassoGeometry.isPointInPolygon(0, 0, const []), isFalse);
    });
  });

  group('LassoGeometry bounds', () {
    test('pathBounds', () {
      final b = LassoGeometry.pathBounds([p(1, 2), p(5, -3), p(4, 9)]);
      expect([b.left, b.top, b.right, b.bottom], [1, -3, 5, 9]);
      expect(LassoGeometry.pathBounds(const []).width, 0);
    });

    test('boundsIntersect', () {
      const a = BoundingBox(left: 0, top: 0, right: 10, bottom: 10);
      const touching = BoundingBox(left: 10, top: 0, right: 20, bottom: 10);
      const apart = BoundingBox(left: 11, top: 0, right: 20, bottom: 10);
      expect(LassoGeometry.boundsIntersect(a, touching), isTrue);
      expect(LassoGeometry.boundsIntersect(a, apart), isFalse);
    });
  });
}
