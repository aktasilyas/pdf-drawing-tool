import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

List<DrawingPoint> _run(StrokeInputFilter f, List<DrawingPoint> input) {
  final out = <DrawingPoint>[f.begin(input.first)];
  for (final p in input.skip(1)) {
    out.addAll(f.add(p));
  }
  final tail = f.end();
  if (tail != null) out.add(tail);
  return out;
}

List<DrawingPoint> _noisyLine() {
  final rnd = math.Random(7);
  return List.generate(
    200,
    (i) => DrawingPoint(
      x: i * 2.0,
      y: 100 + (rnd.nextDouble() - 0.5) * 1.6,
      pressure: 0.5,
      timestamp: i * 8,
    ),
  );
}

void main() {
  group('OneEuroFilter', () {
    test('first sample passes through', () {
      expect(OneEuroFilter().filter(5, 0.01), 5);
    });

    test('converges to a constant signal', () {
      final f = OneEuroFilter(minCutoff: 1.0);
      var v = 0.0;
      for (var i = 0; i < 500; i++) {
        v = f.filter(10, 0.01);
      }
      expect(v, closeTo(10, 1e-6));
    });
  });

  group('StrokeInputFilter', () {
    test('is deterministic', () {
      final a = _run(StrokeInputFilter(), _noisyLine());
      final b = _run(StrokeInputFilter(), _noisyLine());
      expect(a, b);
      expect(a, isNotEmpty);
    });

    test('noisy straight line deviates < 0.5 px from the ideal line', () {
      final out = _run(StrokeInputFilter(), _noisyLine());
      // The first point has no history to filter against, so it stays raw.
      for (final p in out.skip(1)) {
        expect((p.y - 100).abs(), lessThan(0.5));
      }
    });

    test('output is resampled to roughly fixed spacing', () {
      const spacing = 1.5;
      final out = _run(
        StrokeInputFilter(const StrokeInputFilterConfig(spacing: spacing)),
        _noisyLine(),
      );
      for (var i = 1; i < out.length - 1; i++) {
        final d = math.sqrt(math.pow(out[i].x - out[i - 1].x, 2) +
            math.pow(out[i].y - out[i - 1].y, 2));
        expect(d, closeTo(spacing, 0.3));
      }
    });

    test('keeps start and end of the stroke', () {
      final input = _noisyLine();
      final out = _run(StrokeInputFilter(), input);
      expect(out.first.x, input.first.x);
      expect(out.last, input.last);
    });
  });

  group('Pen tools use the input filter', () {
    test('PenTool filters by default and can opt out', () {
      final input = _noisyLine();
      Stroke? draw(PenTool t) {
        t.onPointerDown(input.first);
        for (final p in input.skip(1)) {
          t.onPointerMove(p);
        }
        return t.onPointerUp();
      }

      final filtered = draw(PenTool())!;
      final raw = draw(PenTool(inputFilter: null))!;
      expect(raw.points.length, input.length);
      expect(filtered.points.length, isNot(input.length));
    });
  });
}
