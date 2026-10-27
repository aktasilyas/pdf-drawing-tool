import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  lassoPrefilterTests();
  group('LassoSelectionTool', () {
    late LassoSelectionTool tool;

    setUp(() {
      tool = LassoSelectionTool();
    });

    group('selection lifecycle', () {
      test('initial state is not selecting', () {
        expect(tool.isSelecting, isFalse);
        expect(tool.currentPath, isEmpty);
      });

      test('startSelection begins selection', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));

        expect(tool.isSelecting, isTrue);
        expect(tool.currentPath.length, equals(1));
      });

      test('updateSelection adds points', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        expect(tool.currentPath.length, equals(3));
      });

      test('updateSelection does nothing when not selecting', () {
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        expect(tool.currentPath, isEmpty);
      });

      test('cancelSelection clears state', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.cancelSelection();

        expect(tool.isSelecting, isFalse);
        expect(tool.currentPath, isEmpty);
      });

      test('startSelection clears previous path', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.startSelection(DrawingPoint(x: 50, y: 50));

        expect(tool.currentPath.length, equals(1));
        expect(tool.currentPath.first.x, equals(50));
      });
    });

    group('endSelection', () {
      test('returns null for less than 3 points', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));

        final result = tool.endSelection([]);

        expect(result, isNull);
        expect(tool.isSelecting, isFalse);
      });

      test('returns empty selection when no strokes provided', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.updateSelection(DrawingPoint(x: 50, y: 100));

        final result = tool.endSelection([]);

        expect(result, isNotNull);
        expect(result!.isEmpty, isTrue);
      });

      test('returns empty selection when no strokes selected', () {
        // Create lasso area (triangle)
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.updateSelection(DrawingPoint(x: 50, y: 100));

        // Stroke outside lasso
        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 200, y: 200))
            .addPoint(DrawingPoint(x: 300, y: 300));

        final result = tool.endSelection([stroke]);

        expect(result, isNotNull);
        expect(result!.isEmpty, isTrue);
      });

      test('returns selection when stroke is inside lasso', () {
        // Create large lasso area (square)
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 200));
        tool.updateSelection(DrawingPoint(x: 0, y: 200));

        // Stroke inside lasso
        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50))
            .addPoint(DrawingPoint(x: 100, y: 100));

        final result = tool.endSelection([stroke]);

        expect(result, isNotNull);
        expect(result!.selectedStrokeIds, contains(stroke.id));
        expect(result.type, equals(SelectionType.lasso));
      });

      test('selects multiple strokes inside lasso', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 200));
        tool.updateSelection(DrawingPoint(x: 0, y: 200));

        final stroke1 = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50))
            .addPoint(DrawingPoint(x: 60, y: 60));

        final stroke2 = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 100, y: 100))
            .addPoint(DrawingPoint(x: 110, y: 110));

        final result = tool.endSelection([stroke1, stroke2]);

        expect(result, isNotNull);
        expect(result!.count, equals(2));
        expect(result.selectedStrokeIds, contains(stroke1.id));
        expect(result.selectedStrokeIds, contains(stroke2.id));
      });

      test('selects stroke with partial points inside', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));
        tool.updateSelection(DrawingPoint(x: 0, y: 100));

        // Stroke with one point inside, one outside
        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50)) // inside
            .addPoint(DrawingPoint(x: 200, y: 200)); // outside

        final result = tool.endSelection([stroke]);

        expect(result, isNotNull);
        expect(result!.selectedStrokeIds, contains(stroke.id));
      });

      test('includes lassoPath in selection', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 200));
        tool.updateSelection(DrawingPoint(x: 0, y: 200));

        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50));

        final result = tool.endSelection([stroke]);

        expect(result!.lassoPath, isNotNull);
        expect(result.lassoPath!.length, greaterThan(0));
      });

      test('closes the lasso path', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50));

        final result = tool.endSelection([stroke]);

        expect(result, isNotNull);
        // Path should be closed (first point == last point)
        final path = result!.lassoPath!;
        expect(path.first.x, equals(path.last.x));
        expect(path.first.y, equals(path.last.y));
      });

      test('clears path after selection', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 200));
        tool.updateSelection(DrawingPoint(x: 0, y: 200));

        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50));

        tool.endSelection([stroke]);

        expect(tool.currentPath, isEmpty);
        expect(tool.isSelecting, isFalse);
      });

      test('calculates correct bounds for selected strokes', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 500, y: 0));
        tool.updateSelection(DrawingPoint(x: 500, y: 500));
        tool.updateSelection(DrawingPoint(x: 0, y: 500));

        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 100, y: 100))
            .addPoint(DrawingPoint(x: 200, y: 200));

        final result = tool.endSelection([stroke]);

        expect(result, isNotNull);
        expect(result!.bounds.left, equals(100));
        expect(result.bounds.top, equals(100));
        expect(result.bounds.right, equals(200));
        expect(result.bounds.bottom, equals(200));
      });
    });

    group('point-in-polygon (ray casting)', () {
      test('detects point inside triangle', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.updateSelection(DrawingPoint(x: 50, y: 100));

        // Stroke inside triangle (explicit ID to avoid collision)
        final insideStroke = Stroke(
          id: 'inside-stroke',
          points: [DrawingPoint(x: 50, y: 30)],
          style: StrokeStyle.pen(),
          createdAt: DateTime.now(),
        );

        // Stroke outside triangle
        final outsideStroke = Stroke(
          id: 'outside-stroke',
          points: [DrawingPoint(x: 150, y: 50)],
          style: StrokeStyle.pen(),
          createdAt: DateTime.now(),
        );

        final result = tool.endSelection([insideStroke, outsideStroke]);

        expect(result, isNotNull);
        expect(result!.selectedStrokeIds, contains('inside-stroke'));
        expect(result.selectedStrokeIds, isNot(contains('outside-stroke')));
      });

      test('detects point inside concave polygon', () {
        // L-shaped polygon
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 50));
        tool.updateSelection(DrawingPoint(x: 50, y: 50));
        tool.updateSelection(DrawingPoint(x: 50, y: 100));
        tool.updateSelection(DrawingPoint(x: 0, y: 100));

        // Point in the L (explicit ID)
        final insideStroke = Stroke(
          id: 'inside-L',
          points: [DrawingPoint(x: 25, y: 75)],
          style: StrokeStyle.pen(),
          createdAt: DateTime.now(),
        );

        // Point in the cut-out area
        final outsideStroke = Stroke(
          id: 'outside-L',
          points: [DrawingPoint(x: 75, y: 75)],
          style: StrokeStyle.pen(),
          createdAt: DateTime.now(),
        );

        final result = tool.endSelection([insideStroke, outsideStroke]);

        expect(result, isNotNull);
        expect(result!.selectedStrokeIds, contains('inside-L'));
        expect(result.selectedStrokeIds, isNot(contains('outside-L')));
      });
    });

    group('selectionType', () {
      test('returns lasso type', () {
        expect(tool.selectionType, equals(SelectionType.lasso));
      });
    });
  });
}

DrawingPoint _pt(double x, double y) => DrawingPoint(x: x, y: y);

Stroke _stroke(String id, List<DrawingPoint> pts) => Stroke(
    id: id, points: pts, style: StrokeStyle.pen(), createdAt: DateTime(2024));

LassoSelectionTool _lasso(List<DrawingPoint> path) {
  final t = LassoSelectionTool()..startSelection(path.first);
  path.skip(1).forEach(t.updateSelection);
  return t;
}

void lassoPrefilterTests() {
  group('LassoSelectionTool bbox prefilter', () {
    final square = [_pt(0, 0), _pt(100, 0), _pt(100, 100), _pt(0, 100)];

    test('bbox overlaps lasso but no point inside -> not selected', () {
      // L-shaped lasso; stroke sits in the notch with points outside.
      final l = [
        _pt(0, 0),
        _pt(100, 0),
        _pt(100, 30),
        _pt(30, 30),
        _pt(30, 100),
        _pt(0, 100)
      ];
      final s = _stroke('s', [_pt(60, 60), _pt(90, 90)]);
      final sel = _lasso(l).endSelection([s]);
      expect(sel!.selectedStrokeIds, isEmpty);
    });

    test('stroke with one point inside is selected', () {
      final s = _stroke('s', [_pt(50, 50), _pt(500, 500)]);
      expect(_lasso(square).endSelection([s])!.selectedStrokeIds, ['s']);
    });

    test('line endpoint inside selects the shape', () {
      final line = Shape.create(
        type: ShapeType.line,
        startPoint: _pt(50, 50),
        endPoint: _pt(500, 500),
        style: StrokeStyle.pen(),
      );
      expect(
          _lasso(square).endSelection([], [line])!.selectedShapeIds, [line.id]);
    });

    test('stroke bounds are cached and do not affect equality', () {
      final a = _stroke('s', [_pt(1, 2), _pt(3, 4)]);
      final b = _stroke('s', [_pt(1, 2), _pt(3, 4)]);
      expect(identical(a.bounds, a.bounds), isTrue);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.addPoint(_pt(10, 10)).bounds!.right, 10);
    });

    test('2000 strokes x 200 points, lasso encloses 10, is fast', () {
      final strokes = <Stroke>[];
      for (var i = 0; i < 2000; i++) {
        final ox = (i % 50) * 200.0 + 1000;
        final oy = (i ~/ 50) * 200.0 + 1000;
        strokes.add(_stroke('s$i',
            [for (var k = 0; k < 200; k++) _pt(ox + k % 100, oy + k % 50)]));
      }
      for (var i = 0; i < 10; i++) {
        strokes[i] = _stroke('in$i',
            [for (var k = 0; k < 200; k++) _pt(10.0 + i, 10.0 + k % 50)]);
      }
      final sw = Stopwatch()..start();
      final sel = _lasso(square).endSelection(strokes);
      sw.stop();
      expect(sel!.selectedStrokeIds.length, 10);
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });
}
