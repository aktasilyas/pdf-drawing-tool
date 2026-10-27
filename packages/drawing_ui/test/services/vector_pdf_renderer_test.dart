import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart'
    show VectorPDFRenderer, VectorRenderOptions;
import 'package:flutter_test/flutter_test.dart';

Stroke _stroke(List<DrawingPoint> points) => Stroke(
      id: 's',
      points: points,
      style: StrokeStyle(color: 0xFF000000, thickness: 2),
      createdAt: DateTime(2026),
    );

/// A straight line with [count] points, one unit apart.
List<DrawingPoint> _line(int count) => [
      for (var i = 0; i < count; i++) DrawingPoint(x: i.toDouble(), y: 10),
    ];

void main() {
  final renderer = VectorPDFRenderer();

  group('colour', () {
    test('opaque ARGB keeps RGB and alpha 1', () {
      final c = renderer.convertColor(0xFFFF8000);
      expect(c.red, 1);
      expect(c.green, closeTo(128 / 255, 1e-9));
      expect(c.blue, 0);
      expect(renderer.extractAlpha(0xFFFF8000), 1);
    });

    test('half-transparent ARGB keeps RGB, alpha ~0.5', () {
      final c = renderer.convertColor(0x800000FF);
      expect([c.red, c.green, c.blue], [0, 0, 1]);
      expect(renderer.extractAlpha(0x800000FF), closeTo(128 / 255, 1e-9));
    });

    test('transparent ARGB has alpha 0', () {
      final c = renderer.convertColor(0x00336699);
      expect(c.red, closeTo(0x33 / 255, 1e-9));
      expect(c.green, closeTo(0x66 / 255, 1e-9));
      expect(c.blue, closeTo(0x99 / 255, 1e-9));
      expect(renderer.extractAlpha(0x00336699), 0);
    });
  });

  group('line cap and join per pen', () {
    // (cap, join): cap 1 round / 2 square; join 0 miter / 1 round.
    const expected = {
      PenType.pencil: (1, 1),
      PenType.hardPencil: (1, 1),
      PenType.ballpointPen: (1, 1),
      PenType.gelPen: (1, 1),
      PenType.dashedPen: (2, 0),
      PenType.highlighter: (2, 0),
      PenType.neonHighlighter: (2, 0),
      PenType.brushPen: (1, 1),
      PenType.rulerPen: (1, 1),
      PenType.fountainPen: (1, 1),
    };

    test('covers every PenType', () {
      expect(expected.keys.toSet(), PenType.values.toSet());
    });

    for (final pen in PenType.values) {
      test(pen.name, () {
        final (cap, join) = expected[pen]!;
        expect(renderer.getRecommendedLineCap(pen), cap);
        expect(renderer.getRecommendedLineJoin(pen), join);
      });
    }
  });

  group('prepareStroke', () {
    test('returns two or fewer points unchanged', () {
      for (final points in [_line(1), _line(2)]) {
        expect(renderer.prepareStroke(_stroke(points)), points);
      }
    });

    test('keeps the first and last point', () {
      final points = [
        DrawingPoint(x: 0, y: 0, pressure: 0.2),
        DrawingPoint(x: 5, y: 9, pressure: 0.6),
        DrawingPoint(x: 10, y: 1, pressure: 0.4),
        DrawingPoint(x: 15, y: 7, pressure: 0.9),
      ];
      final out = renderer.prepareStroke(_stroke(points));
      expect(out.first, points.first);
      expect(out.last, points.last);
      expect(out, hasLength(points.length));
    });

    test('reduces a dense straight line when optimisation is on', () {
      final points = _line(1500);
      final out = renderer.prepareStroke(_stroke(points));
      expect(out.length, lessThan(points.length));
      expect(out.first, points.first);
      expect(out.last, points.last);
    });

    test('keeps every point when optimisation is off', () {
      final points = _line(1500);
      final out = renderer.prepareStroke(
        _stroke(points),
        options: const VectorRenderOptions(
          optimizePaths: false,
          smoothStrokes: false,
        ),
      );
      expect(out, points);
    });
  });
}
