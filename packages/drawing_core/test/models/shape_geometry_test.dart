import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

Shape _shape(ShapeType type) => Shape(
      id: 's',
      type: type,
      startPoint: DrawingPoint(x: 10, y: 20),
      endPoint: DrawingPoint(x: 110, y: 80),
      style: StrokeStyle.pen(),
    );

void main() {
  group('ShapeGeometry.polygonPaths', () {
    test('native primitives have no polygon geometry', () {
      for (final type in [
        ShapeType.line,
        ShapeType.arrow,
        ShapeType.rectangle,
        ShapeType.ellipse,
      ]) {
        expect(ShapeGeometry.polygonPaths(_shape(type)), isNull,
            reason: type.name);
      }
    });

    test('every other ShapeType has polygon geometry', () {
      for (final type in ShapeType.values) {
        if (ShapeGeometry.isNative(type)) continue;
        final paths = ShapeGeometry.polygonPaths(_shape(type));
        expect(paths, isNotNull, reason: type.name);
        expect(paths, isNotEmpty, reason: type.name);
      }
    });

    test('triangle: apex top-centre, base bottom corners', () {
      final p = ShapeGeometry.polygonPaths(_shape(ShapeType.triangle))!;
      expect(p, hasLength(1));
      expect(p.single.closed, isTrue);
      expect(p.single.points, const [
        Point2D(60, 20),
        Point2D(10, 80),
        Point2D(110, 80),
      ]);
    });

    test('diamond: top, right, bottom, left mid-points', () {
      final p = ShapeGeometry.polygonPaths(_shape(ShapeType.diamond))!;
      expect(p.single.closed, isTrue);
      expect(p.single.points, const [
        Point2D(60, 20),
        Point2D(110, 50),
        Point2D(60, 80),
        Point2D(10, 50),
      ]);
    });

    test('pentagon and hexagon are regular polygons in the bounds', () {
      for (final (type, sides) in [
        (ShapeType.pentagon, 5),
        (ShapeType.hexagon, 6),
      ]) {
        final p = ShapeGeometry.polygonPaths(_shape(type))!;
        expect(p.single.closed, isTrue);
        final pts = p.single.points;
        expect(pts, hasLength(sides));
        // First vertex points straight up.
        expect(pts.first.x, closeTo(60, 1e-9));
        expect(pts.first.y, closeTo(20, 1e-9));
        for (var i = 0; i < sides; i++) {
          final a = i * 2 * math.pi / sides - math.pi / 2;
          expect(pts[i].x, closeTo(60 + 50 * math.cos(a), 1e-9));
          expect(pts[i].y, closeTo(50 + 30 * math.sin(a), 1e-9));
        }
      }
    });

    test('star: 10 vertices alternating outer and 0.4 inner radius', () {
      final p = ShapeGeometry.polygonPaths(_shape(ShapeType.star))!;
      expect(p.single.closed, isTrue);
      final pts = p.single.points;
      expect(pts, hasLength(10));
      for (var i = 0; i < 10; i++) {
        final scale = i.isEven ? 1.0 : 0.4;
        final a = i * math.pi / 5 - math.pi / 2;
        expect(pts[i].x, closeTo(60 + 50 * scale * math.cos(a), 1e-9));
        expect(pts[i].y, closeTo(50 + 30 * scale * math.sin(a), 1e-9));
      }
    });

    test('star with zero size does not produce NaN', () {
      final shape = Shape(
        id: 's',
        type: ShapeType.star,
        startPoint: DrawingPoint(x: 5, y: 5),
        endPoint: DrawingPoint(x: 5, y: 5),
        style: StrokeStyle.pen(),
      );
      final pts = ShapeGeometry.polygonPaths(shape)!.single.points;
      expect(pts.every((p) => p.x.isFinite && p.y.isFinite), isTrue);
    });

    test('plus: two open bars through the centre', () {
      final p = ShapeGeometry.polygonPaths(_shape(ShapeType.plus))!;
      expect(p, hasLength(2));
      expect(p.every((path) => !path.closed), isTrue);
      expect(p[0].points, const [Point2D(60, 20), Point2D(60, 80)]);
      expect(p[1].points, const [Point2D(10, 50), Point2D(110, 50)]);
    });

    test('reversed drag (end before start) gives the same outline', () {
      final reversed = Shape(
        id: 's',
        type: ShapeType.triangle,
        startPoint: DrawingPoint(x: 110, y: 80),
        endPoint: DrawingPoint(x: 10, y: 20),
        style: StrokeStyle.pen(),
      );
      expect(
        ShapeGeometry.polygonPaths(reversed)!.single.points,
        ShapeGeometry.polygonPaths(_shape(ShapeType.triangle))!.single.points,
      );
    });
  });
}
