import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/selection_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

const _b = BoundingBox(left: 100, top: 100, right: 300, bottom: 200);

void main() {
  group('hitRadius', () {
    for (final zoom in [0.5, 1.0, 3.0]) {
      test('is at least 24 screen pixels at zoom $zoom', () {
        expect(SelectionGeometry.hitRadius(zoom) * zoom,
            greaterThanOrEqualTo(24.0));
      });
    }

    test('grows in canvas units when zoomed out', () {
      expect(SelectionGeometry.hitRadius(0.5), 48.0);
      expect(SelectionGeometry.hitRadius(1.0), 24.0);
    });

    test('never drops below the drawn handle size when zoomed in', () {
      expect(SelectionGeometry.hitRadius(3.0),
          SelectionGeometry.minCanvasHitRadius);
    });

    test('falls back for a non-positive zoom', () {
      expect(SelectionGeometry.hitRadius(0), 22.0);
    });
  });

  group('hitTest', () {
    for (final zoom in [0.5, 1.0, 3.0]) {
      test('grabs a corner 23.5 screen px away at zoom $zoom', () {
        // 23.5 screen pixels to the left of the bottom-left corner.
        final p = Offset(100 - 23.5 / zoom, 200);
        final hit = SelectionGeometry.hitTest(p, _b, zoom: zoom);
        expect(hit?.mode, SelectionDragMode.scale);
        expect(hit?.handle, SelectionHandle.bottomLeft);
        expect(hit?.anchor, const Offset(100, 200));
      });

      test('grabs the rotation handle 23.5 screen px away at zoom $zoom', () {
        final rot = SelectionGeometry.rotationHandle(_b);
        final p = rot + Offset(23.5 / zoom, 0);
        // At zoom 0.5 the top-center handle could also be in range; the
        // rotation handle is nearer and wins.
        final hit = SelectionGeometry.hitTest(p, _b, zoom: zoom);
        expect(hit?.mode, SelectionDragMode.rotate);
        expect(hit?.anchor, p);
      });
    }

    test('misses a corner 25 screen px away at zoom 1', () {
      final hit = SelectionGeometry.hitTest(
        const Offset(75, 200),
        _b,
      );
      expect(hit, isNull);
    });

    test('picks the nearest of overlapping handles', () {
      // Between rotation handle (200, 64) and top-center (200, 100),
      // closer to top-center.
      final hit = SelectionGeometry.hitTest(
        const Offset(200, 90),
        _b,
        zoom: 0.5,
      );
      expect(hit?.mode, SelectionDragMode.scale);
      expect(hit?.handle, SelectionHandle.topCenter);
    });

    test('inside the body away from handles is a move', () {
      const p = Offset(160, 150);
      final hit = SelectionGeometry.hitTest(p, _b);
      expect(hit?.mode, SelectionDragMode.move);
      expect(hit?.anchor, p);
      expect(hit?.handle, isNull);
    });

    test('outside everything is null', () {
      expect(SelectionGeometry.hitTest(const Offset(500, 500), _b), isNull);
    });
  });

  test('contains includes the edges', () {
    expect(SelectionGeometry.contains(const Offset(100, 100), _b), isTrue);
    expect(SelectionGeometry.contains(const Offset(301, 150), _b), isFalse);
  });

  test('isCorner', () {
    expect(SelectionGeometry.isCorner(SelectionHandle.topRight), isTrue);
    expect(SelectionGeometry.isCorner(SelectionHandle.topCenter), isFalse);
  });

  test('angleAround measures from the centre', () {
    expect(SelectionGeometry.angleAround(const Offset(300, 150), _b), 0.0);
    expect(SelectionGeometry.angleAround(const Offset(200, 250), _b),
        closeTo(math.pi / 2, 1e-9));
  });

  group('clampMove', () {
    test('is unchanged on an infinite canvas', () {
      const d = Offset(-500, 900);
      expect(SelectionGeometry.clampMove(d, _b, null), d);
    });

    test('keeps the selection on the page', () {
      final d = SelectionGeometry.clampMove(
        const Offset(-500, 900),
        _b,
        const Size(400, 400),
      );
      expect(d, const Offset(-100, 200));
    });

    test('leaves an axis free when the selection is larger than the page', () {
      final d = SelectionGeometry.clampMove(
        const Offset(50, 10),
        _b,
        const Size(150, 400),
      );
      expect(d, const Offset(50, 10));
    });
  });

  group('scaleFor', () {
    test('corner scales uniformly from the centre', () {
      final s = SelectionGeometry.scaleFor(
        handle: SelectionHandle.bottomRight,
        b: _b,
        dragStart: const Offset(300, 200),
        pos: const Offset(400, 250),
      );
      expect(s!.$1, closeTo(2.0, 1e-9));
      expect(s.$2, s.$1);
    });

    test('edge scales along one axis', () {
      final s = SelectionGeometry.scaleFor(
        handle: SelectionHandle.middleRight,
        b: _b,
        dragStart: const Offset(300, 150),
        pos: const Offset(350, 170),
      );
      expect(s, (1.5, 1.0));
      final v = SelectionGeometry.scaleFor(
        handle: SelectionHandle.topCenter,
        b: _b,
        dragStart: const Offset(200, 100),
        pos: const Offset(200, 125),
      );
      expect(v, (1.0, 0.5));
    });

    test('never shrinks below minSize', () {
      final s = SelectionGeometry.scaleFor(
        handle: SelectionHandle.middleRight,
        b: _b,
        dragStart: const Offset(300, 150),
        pos: const Offset(200, 150),
      );
      expect(s!.$1 * 200, closeTo(SelectionGeometry.minSize, 1e-9));
      expect(s.$2, 1.0);
    });

    test('is clamped to the page and stays uniform for corners', () {
      final s = SelectionGeometry.scaleFor(
        handle: SelectionHandle.bottomRight,
        b: _b,
        dragStart: const Offset(300, 200),
        pos: const Offset(600, 350),
        pageSize: const Size(400, 400),
      );
      // Centre (200, 150): x may grow to 2.0, y to 3.0 → uniform 2.0.
      expect(s, (2.0, 2.0));
    });

    test('is null for a degenerate selection', () {
      final s = SelectionGeometry.scaleFor(
        handle: SelectionHandle.bottomRight,
        b: const BoundingBox(left: 0, top: 0, right: 1, bottom: 1),
        dragStart: const Offset(1, 1),
        pos: const Offset(5, 5),
      );
      expect(s, isNull);
    });

    test('is null when dragging from the centre', () {
      final s = SelectionGeometry.scaleFor(
        handle: SelectionHandle.bottomRight,
        b: _b,
        dragStart: const Offset(200, 150),
        pos: const Offset(300, 200),
      );
      expect(s, isNull);
    });
  });

  test('translate moves every edge', () {
    final t = SelectionGeometry.translate(_b, const Offset(10, -5));
    expect(t, const BoundingBox(left: 110, top: 95, right: 310, bottom: 195));
  });

  group('union', () {
    test('is null for no boxes', () {
      expect(SelectionGeometry.union(const []), isNull);
    });

    test('covers every box', () {
      final u = SelectionGeometry.union(const [
        _b,
        BoundingBox(left: 0, top: 150, right: 120, bottom: 400),
      ]);
      expect(u, const BoundingBox(left: 0, top: 100, right: 300, bottom: 400));
    });
  });
}
