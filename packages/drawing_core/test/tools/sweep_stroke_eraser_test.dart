import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

/// Pen stroke resampled every [spacing] px from (x0, y) to (x1, y), like the
/// input filter (#41) produces.
Stroke _line({
  String id = 's',
  double x0 = 0,
  double x1 = 600,
  double y = 100,
  double spacing = 1.5,
  double thickness = 2,
}) {
  final n = ((x1 - x0) / spacing).round();
  final points = <DrawingPoint>[];
  for (var i = 0; i <= n; i++) {
    final x = x0 + (x1 - x0) * i / n;
    points.add(DrawingPoint(x: x, y: y, pressure: 0.5, timestamp: i));
  }
  final style = StrokeStyle(color: 0xFF000000, thickness: thickness);
  return Stroke(id: id, points: points, style: style, createdAt: _t0);
}

final _t0 = DateTime(2026);

/// Capsules of a sweep through samples given as flat (x, y, radius) triples.
List<EraserCapsule> _sweep(List<double> xyr) {
  final sweep = EraserSweep();
  for (var i = 0; i + 2 < xyr.length; i += 3) {
    sweep.add(xyr[i], xyr[i + 1], xyr[i + 2]);
  }
  return sweep.capsules;
}

void main() {
  group('EraserSweep', () {
    test('first sample is a disc, later samples join the previous one', () {
      final sweep = EraserSweep();
      final a = sweep.add(10, 20, 5);
      final b = sweep.add(50, 20, 3);

      expect([a.x0, a.y0, a.x1, a.y1], [10, 20, 10, 20]);
      expect([b.x0, b.y0, b.x1, b.y1], [10, 20, 50, 20]);
      // Larger of both radii so a pressure drop leaves no gap.
      expect(b.radius, 5);
      expect(sweep.capsules, hasLength(2));

      sweep.clear();
      expect(sweep.isEmpty, isTrue);
      final c = sweep.add(0, 0, 1);
      expect([c.x0, c.x1], [0, 0]);
    });

    test('capsule distance covers the space between samples', () {
      const c = EraserCapsule(x0: 0, y0: 0, x1: 100, y1: 0, radius: 4);
      expect(c.distanceToPoint(50, 3), closeTo(3, 1e-9));
      expect(c.distanceToSegment(50, -10, 50, 10), 0);
      expect(c.distanceToSegment(120, 0, 130, 0), closeTo(20, 1e-9));
    });
  });

  group('SweepStrokeEraser', () {
    test('fast sweep along a dense stroke cuts one gap, not dashes', () {
      // Regression for #125: eraser samples 60 px apart, radius 5. Hit
      // testing only at the samples left kept ink between them, so the
      // stroke turned into dashes.
      final stroke = _line();
      final sweep = _sweep([100, 100, 5, 160, 100, 5, 220, 100, 5]);

      final pieces = SweepStrokeEraser.erase(stroke, sweep)!;

      expect(pieces, hasLength(2));
      // reach = radius 5 + half thickness 1
      expect(pieces[0].points.first.x, 0);
      expect(pieces[0].points.last.x, closeTo(94, 0.05));
      expect(pieces[1].points.first.x, closeTo(226, 0.05));
      expect(pieces[1].points.last.x, 600);
      expect(pieces.map((p) => p.id), ['s_split_0', 's_split_1']);
    });

    test('kept ink never reaches into the swept area', () {
      // Sparse legacy stroke, zig-zag sweep with varying radius.
      final stroke = _line(spacing: 7);
      final sweep = _sweep([50, 60, 8, 180, 140, 8, 320, 70, 6, 450, 130, 10]);

      final pieces = SweepStrokeEraser.erase(stroke, sweep)!;

      expect(pieces, isNotEmpty);
      for (final piece in pieces) {
        for (var i = 1; i < piece.points.length; i++) {
          final a = piece.points[i - 1];
          final b = piece.points[i];
          for (var t = 0.0; t <= 1.0; t += 0.1) {
            final x = a.x + (b.x - a.x) * t;
            final y = a.y + (b.y - a.y) * t;
            // Reach is radius + 1; allow the bisection tolerance.
            for (final c in sweep) {
              final reach = c.radius + 1 - 0.01;
              expect(c.distanceToPoint(x, y), greaterThan(reach));
            }
          }
        }
      }
    });

    test('ink outside the swept area is kept', () {
      final stroke = _line();
      final sweep = _sweep([300, 40, 10, 300, 160, 10]);

      final pieces = SweepStrokeEraser.erase(stroke, sweep)!;

      // Every original point farther than reach (11) + tolerance survives.
      final kept = [for (final p in pieces) ...p.points];
      for (final p in stroke.points) {
        if ((p.x - 300).abs() > 11.01) {
          final survived = kept.any((k) => k.x == p.x && k.y == p.y);
          expect(survived, isTrue, reason: 'x=${p.x} must survive');
        }
      }
      expect(pieces, hasLength(2));
      expect(pieces[0].points.last.x, closeTo(289, 0.05));
      expect(pieces[1].points.first.x, closeTo(311, 0.05));
    });

    test('cuts a long two-point segment instead of dropping it', () {
      final stroke = _line(spacing: 600);
      expect(stroke.points, hasLength(2));

      final pieces = SweepStrokeEraser.erase(stroke, _sweep([300, 100, 10]))!;

      expect(pieces, hasLength(2));
      expect(pieces[0].points.first.x, 0);
      expect(pieces[0].points.last.x, closeTo(289, 0.05));
      expect(pieces[1].points.first.x, closeTo(311, 0.05));
      expect(pieces[1].points.last.x, 600);
    });

    test('cut points interpolate pressure and timestamp', () {
      final a = DrawingPoint(x: 0, y: 0, pressure: 0.2, timestamp: 0);
      final b = DrawingPoint(x: 100, y: 0, pressure: 1.0, timestamp: 100);
      final style = StrokeStyle(color: 0xFF000000, thickness: 0);
      final s = Stroke(id: 'p', points: [a, b], style: style, createdAt: _t0);

      final pieces = SweepStrokeEraser.erase(s, _sweep([100, 0, 50]))!;

      expect(pieces, hasLength(1));
      final cut = pieces.single.points.last;
      expect(cut.x, closeTo(50, 0.1));
      expect(cut.pressure, closeTo(0.6, 0.01));
      expect(cut.timestamp, closeTo(50, 1));
    });

    test('untouched stroke returns null', () {
      final sweep = _sweep([300, 300, 10, 400, 300, 10]);
      expect(SweepStrokeEraser.erase(_line(), sweep), isNull);
    });

    test('stroke fully inside the sweep is removed', () {
      final stroke = _line(x0: 100, x1: 140);
      final sweep = _sweep([90, 100, 12, 150, 100, 12]);
      expect(SweepStrokeEraser.erase(stroke, sweep), isEmpty);
    });

    test('dot stroke inside the sweep is removed, else untouched', () {
      final style = StrokeStyle(color: 0xFF000000, thickness: 4);
      final p = DrawingPoint(x: 10, y: 10);
      final dot = Stroke(id: 'd', points: [p], style: style, createdAt: _t0);

      expect(SweepStrokeEraser.erase(dot, _sweep([0, 10, 9])), isEmpty);
      expect(SweepStrokeEraser.erase(dot, _sweep([0, 10, 5])), isNull);
    });

    test('pieces keep the original style and createdAt', () {
      final stroke = _line(thickness: 3);

      final pieces = SweepStrokeEraser.erase(stroke, _sweep([300, 100, 5]))!;

      for (final p in pieces) {
        expect(p.style, stroke.style);
        expect(p.createdAt, stroke.createdAt);
      }
    });

    test('undo through ErasePointsCommand restores the stroke exactly', () {
      final stroke = _line();
      final layer = Layer.empty('Layer 1').copyWith(strokes: [stroke]);
      final doc = DrawingDocument.emptyMultiPage('Test');
      final page = doc.pages.first.copyWith(layers: [layer]);
      final document = doc.copyWith(pages: [page]);
      final sweep = _sweep([100, 100, 5, 400, 100, 5]);
      final pieces = SweepStrokeEraser.erase(stroke, sweep)!;

      final command = ErasePointsCommand(
        layerIndex: 0,
        originalStrokes: [stroke],
        resultingStrokes: pieces,
      );
      final erased = command.execute(document);
      final ids = erased.layers[0].strokes.map((s) => s.id);
      expect(ids, ['s_split_0', 's_split_1']);

      final restored = command.undo(erased);
      expect(restored.layers[0].strokes, [stroke]);
      final order = document.layers[0].elementOrder;
      expect(restored.layers[0].elementOrder, order);
    });
  });

  group('PixelEraserTool.findSegmentsAlong', () {
    test('hits every segment between two far apart samples', () {
      final stroke = _line();
      final capsule = _sweep([100, 100, 5, 160, 100, 5]).last;

      final hits = PixelEraserTool().findSegmentsAlong([stroke], capsule);
      final indices = hits.map((h) => h.segmentIndex).toSet();

      // Segments from x≈94 to x≈166 (reach 6) are all hit, without holes.
      final first = indices.reduce(math.min);
      final last = indices.reduce(math.max);
      expect(indices.length, last - first + 1);
      expect(stroke.points[first].x, lessThan(100 - 5));
      expect(stroke.points[last + 1].x, greaterThan(160 + 5));
    });

    test('skips strokes outside the capsule bounds', () {
      final capsule = _sweep([100, 300, 5, 160, 300, 5]).last;
      final hits = PixelEraserTool().findSegmentsAlong([_line()], capsule);
      expect(hits, isEmpty);
    });
  });
}
