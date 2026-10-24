import 'dart:ui';

import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TileGrid', () {
    test('tile extent is 512 / scale', () {
      expect(TileGrid(scale: 1).tileExtent, 512);
      expect(TileGrid(scale: 2).tileExtent, 256);
      expect(TileGrid(scale: 8).tileExtent, 64);
    });

    test('keysIn at scale 1', () {
      final g = TileGrid(scale: 1);
      expect(g.keysIn(const Rect.fromLTWH(10, 10, 100, 100)),
          [const TileKey(0, 0)]);
      expect(g.keysIn(const Rect.fromLTWH(500, 500, 20, 20)), [
        const TileKey(0, 0),
        const TileKey(1, 0),
        const TileKey(0, 1),
        const TileKey(1, 1),
      ]);
    });

    test('touching edge does not include neighbour tile', () {
      final g = TileGrid(scale: 1);
      expect(
          g.keysIn(const Rect.fromLTRB(0, 0, 512, 512)), [const TileKey(0, 0)]);
    });

    test('keysIn at scale 2.6 and 8 cover the rect', () {
      for (final s in [2.6, 8.0]) {
        final g = TileGrid(scale: s);
        const r = Rect.fromLTWH(37.3, 91.1, 400, 300);
        final keys = g.keysIn(r);
        final union = keys.map(g.rectOf).reduce((a, b) => a.expandToInclude(b));
        expect(union.left, lessThanOrEqualTo(r.left));
        expect(union.top, lessThanOrEqualTo(r.top));
        expect(union.right, greaterThanOrEqualTo(r.right));
        expect(union.bottom, greaterThanOrEqualTo(r.bottom));
        for (final k in keys) {
          expect(g.rectOf(k).overlaps(r), isTrue);
        }
      }
    });

    test('tile rects cover the page with no gaps', () {
      for (final s in [1.0, 2.6, 8.0]) {
        final g = TileGrid(scale: s);
        const page = Rect.fromLTWH(0, 0, 595, 842);
        final keys = g.keysIn(page);
        final area = keys.fold<double>(
            0, (sum, k) => sum + g.rectOf(k).width * g.rectOf(k).height);
        final union = keys.map(g.rectOf).reduce((a, b) => a.expandToInclude(b));
        expect(union.width * union.height, closeTo(area, 1e-6));
        expect(union.contains(page.topLeft), isTrue);
        expect(union.right, greaterThanOrEqualTo(page.right));
        expect(union.bottom, greaterThanOrEqualTo(page.bottom));
      }
    });

    test('clip limits keys; empty rect gives none', () {
      final g = TileGrid(scale: 1);
      expect(
        g.keysIn(const Rect.fromLTWH(0, 0, 2000, 2000),
            clip: const Rect.fromLTWH(0, 0, 100, 100)),
        [const TileKey(0, 0)],
      );
      expect(g.keysIn(Rect.zero), isEmpty);
    });

    test('negative coordinates map to negative keys', () {
      final g = TileGrid(scale: 1);
      expect(
          g.keysIn(const Rect.fromLTWH(-10, 0, 5, 5)), [const TileKey(-1, 0)]);
    });

    test('TileKey equality', () {
      expect(const TileKey(1, 2), const TileKey(1, 2));
      expect(const TileKey(1, 2).hashCode, const TileKey(1, 2).hashCode);
      expect(const TileKey(1, 2), isNot(const TileKey(2, 1)));
    });
  });
}
