import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_handles_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

const _img = ImageElement(
  id: 'i',
  filePath: 'a.png',
  x: 100,
  y: 100,
  width: 200,
  height: 100,
);

void main() {
  group('toLocal / toCanvas', () {
    test('identity when not rotated', () {
      expect(ImageHandlesGeometry.toLocal(const Offset(5, 7), _img),
          const Offset(5, 7));
      expect(ImageHandlesGeometry.toCanvas(const Offset(5, 7), _img),
          const Offset(5, 7));
    });

    test('round-trips for a 90° rotated image', () {
      final r = _img.copyWith(rotation: math.pi / 2);
      const p = Offset(130, 40);
      final back =
          ImageHandlesGeometry.toCanvas(ImageHandlesGeometry.toLocal(p, r), r);
      expect(back.dx, closeTo(p.dx, 1e-9));
      expect(back.dy, closeTo(p.dy, 1e-9));
    });

    test('90° rotation moves the top-left corner as expected', () {
      final r = _img.copyWith(rotation: math.pi / 2);
      // center (200,150); top-left (100,100) -> offset (-100,-50) -> (50,-100)
      final c = ImageHandlesGeometry.toCanvas(
          ImageHandlesGeometry.cornerLocal(ImageCorner.topLeft, r), r);
      expect(c.dx, closeTo(250, 1e-9));
      expect(c.dy, closeTo(50, 1e-9));
    });
  });

  group('hit testing', () {
    test('corner hit within 24 radius, miss outside', () {
      expect(ImageHandlesGeometry.hitCorner(const Offset(100 + 23, 100), _img),
          ImageCorner.topLeft);
      expect(ImageHandlesGeometry.hitCorner(const Offset(100 + 25, 100), _img),
          isNull);
      expect(ImageHandlesGeometry.hitCorner(const Offset(300, 200), _img),
          ImageCorner.bottomRight);
    });

    test('corner hit on a rotated image uses canvas positions', () {
      final r = _img.copyWith(rotation: math.pi / 2);
      expect(ImageHandlesGeometry.hitCorner(const Offset(250, 50), r),
          ImageCorner.topLeft);
      expect(ImageHandlesGeometry.hitCorner(const Offset(100, 100), r), isNull);
    });

    test('rotation handle hit', () {
      expect(
          ImageHandlesGeometry.hitRotationHandle(const Offset(200, 70), _img),
          isTrue);
      expect(
          ImageHandlesGeometry.hitRotationHandle(const Offset(200, 100), _img),
          isFalse);
    });

    test('isInsideLocal', () {
      expect(ImageHandlesGeometry.isInsideLocal(const Offset(200, 150), _img),
          isTrue);
      expect(ImageHandlesGeometry.isInsideLocal(const Offset(50, 150), _img),
          isFalse);
    });
  });

  group('resize', () {
    test('bottomRight grows', () {
      final r = ImageHandlesGeometry.resize(
          ImageCorner.bottomRight, _img, const Offset(400, 300));
      expect([r.x, r.y, r.width, r.height], [100, 100, 300, 200]);
    });

    test('topLeft keeps the opposite corner fixed', () {
      final r = ImageHandlesGeometry.resize(
          ImageCorner.topLeft, _img, const Offset(50, 60));
      expect([r.x, r.y, r.width, r.height], [50, 60, 250, 140]);
    });

    test('bottomLeft and topRight', () {
      final bl = ImageHandlesGeometry.resize(
          ImageCorner.bottomLeft, _img, const Offset(150, 250));
      expect([bl.x, bl.y, bl.width, bl.height], [150, 100, 150, 150]);
      final tr = ImageHandlesGeometry.resize(
          ImageCorner.topRight, _img, const Offset(350, 80));
      expect([tr.x, tr.y, tr.width, tr.height], [100, 80, 250, 120]);
    });

    test('enforces the 50px minimum on every corner', () {
      final br = ImageHandlesGeometry.resize(
          ImageCorner.bottomRight, _img, const Offset(0, 0));
      expect([br.width, br.height], [50, 50]);
      final tl = ImageHandlesGeometry.resize(
          ImageCorner.topLeft, _img, const Offset(900, 900));
      expect([tl.x, tl.y, tl.width, tl.height], [250, 150, 50, 50]);
    });

    test('rotated image: drag in local frame', () {
      final rot = _img.copyWith(rotation: math.pi / 2);
      // Pointer at canvas (250,250): local = toLocal.
      final local = ImageHandlesGeometry.toLocal(const Offset(250, 250), rot);
      final r =
          ImageHandlesGeometry.resize(ImageCorner.bottomRight, rot, local);
      expect(r.width, greaterThanOrEqualTo(ImageHandlesGeometry.minSize));
      expect(r.rotation, rot.rotation);
    });
  });

  group('rotation', () {
    test('pointer straight above gives 0 rotation', () {
      expect(ImageHandlesGeometry.rotationFor(const Offset(200, 0), _img),
          closeTo(0, 1e-9));
    });

    test('pointer to the right gives 90°', () {
      expect(ImageHandlesGeometry.rotationFor(const Offset(500, 150), _img),
          closeTo(math.pi / 2, 1e-9));
    });
  });

  group('clampToPage', () {
    test('clamps to page bounds', () {
      final r = ImageHandlesGeometry.clampToPage(
          _img.copyWith(x: -50, y: 900), 595, 842);
      expect([r.x, r.y], [0, 742]);
      final r2 = ImageHandlesGeometry.clampToPage(
          _img.copyWith(x: 900, y: -5), 595, 842);
      expect([r2.x, r2.y], [395, 0]);
    });

    test('image larger than page pins to 0', () {
      final r = ImageHandlesGeometry.clampToPage(
          _img.copyWith(x: 30, width: 900), 595, 842);
      expect(r.x, 0);
    });
  });

  test('changed detects geometry differences only', () {
    expect(ImageHandlesGeometry.changed(_img, _img), isFalse);
    expect(ImageHandlesGeometry.changed(_img, _img.copyWith(rotation: 0.1)),
        isTrue);
    expect(
        ImageHandlesGeometry.changed(_img, _img.copyWith(width: 201)), isTrue);
  });
}
