import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/vector_pdf_renderer.dart';

void main() {
  group('VectorPDFRenderer', () {
    late VectorPDFRenderer renderer;

    setUp(() {
      renderer = VectorPDFRenderer();
    });

    group('Constructor', () {
      test('should create with default settings', () {
        final renderer = VectorPDFRenderer();
        expect(renderer, isNotNull);
      });

      test('should create with custom settings', () {
        final renderer = VectorPDFRenderer(
          enableAntialiasing: false,
        );
        expect(renderer, isNotNull);
      });
    });

    group('Stroke Rendering', () {
      test('should support basic stroke', () {
        final stroke = Stroke(
          id: 's1',
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
        );

        expect(renderer.canRenderStroke(stroke), true);
      });

      test('should support pressure-sensitive strokes', () {
        final stroke = Stroke(
          id: 's1',
          points: [
            DrawingPoint(x: 0, y: 0, pressure: 0.5),
            DrawingPoint(x: 100, y: 100, pressure: 1.0),
          ],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
        );

        expect(renderer.canRenderStroke(stroke), true);
      });

      test('should reject stroke with less than 2 points', () {
        final stroke = Stroke(
          id: 's1',
          points: [DrawingPoint(x: 0, y: 0)],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
        );

        expect(renderer.canRenderStroke(stroke), false);
      });

      test('should reject empty stroke', () {
        final stroke = Stroke(
          id: 's1',
          points: [],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
        );

        expect(renderer.canRenderStroke(stroke), false);
      });

      test('should calculate stroke path length', () {
        final stroke = Stroke(
          id: 's1',
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
        );

        final length = renderer.calculateStrokeLength(stroke);
        expect(length, closeTo(200.0, 0.1));
      });
    });

    group('Shape Rendering', () {
      test('should support rectangle', () {
        final shape = Shape.create(
          type: ShapeType.rectangle,
          point1: DrawingPoint(x: 0, y: 0),
          point2: DrawingPoint(x: 100, y: 100),
        );

        expect(renderer.canRenderShape(shape), true);
      });

      test('should support ellipse', () {
        final shape = Shape.create(
          type: ShapeType.ellipse,
          point1: DrawingPoint(x: 0, y: 0),
          point2: DrawingPoint(x: 100, y: 100),
        );

        expect(renderer.canRenderShape(shape), true);
      });

      test('should support line', () {
        final shape = Shape.create(
          type: ShapeType.line,
          point1: DrawingPoint(x: 0, y: 0),
          point2: DrawingPoint(x: 100, y: 100),
        );

        expect(renderer.canRenderShape(shape), true);
      });

      test('should support triangle', () {
        final shape = Shape.create(
          type: ShapeType.triangle,
          point1: DrawingPoint(x: 0, y: 0),
          point2: DrawingPoint(x: 100, y: 100),
        );

        expect(renderer.canRenderShape(shape), true);
      });

      test('should support diamond', () {
        final shape = Shape.create(
          type: ShapeType.diamond,
          point1: DrawingPoint(x: 0, y: 0),
          point2: DrawingPoint(x: 100, y: 100),
        );

        expect(renderer.canRenderShape(shape), true);
      });

      test('should calculate shape area', () {
        final shape = Shape.create(
          type: ShapeType.rectangle,
          point1: DrawingPoint(x: 0, y: 0),
          point2: DrawingPoint(x: 100, y: 50),
        );

        final area = renderer.calculateShapeArea(shape);
        expect(area, 5000.0); // 100 * 50
      });
    });

    group('Text Rendering', () {
      test('should support basic text', () {
        final text = TextElement(
          id: 't1',
          content: 'Hello',
          position: DrawingPoint(x: 0, y: 0),
          size: Size(width: 100, height: 20),
          style: TextStyle.create(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(renderer.canRenderText(text), true);
      });

      test('should reject empty text', () {
        final text = TextElement(
          id: 't1',
          content: '',
          position: DrawingPoint(x: 0, y: 0),
          size: Size(width: 100, height: 20),
          style: TextStyle.create(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(renderer.canRenderText(text), false);
      });

      test('should calculate text width estimate', () {
        final text = TextElement(
          id: 't1',
          content: 'Hello',
          position: DrawingPoint(x: 0, y: 0),
          size: Size(width: 100, height: 20),
          style: TextStyle.create(fontSize: 16),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final width = renderer.estimateTextWidth(text);
        expect(width, greaterThan(0));
      });
    });

    group('Pen Style Support', () {
      test('should support ballpoint pen', () {
        expect(renderer.supportsPenStyle(PenType.ballpointPen), true);
      });

      test('should support fountain pen', () {
        expect(renderer.supportsPenStyle(PenType.fountainPen), true);
      });

      test('should support marker', () {
        expect(renderer.supportsPenStyle(PenType.marker), true);
      });

      test('should support highlighter', () {
        expect(renderer.supportsPenStyle(PenType.highlighter), true);
      });

      test('should support pencil', () {
        expect(renderer.supportsPenStyle(PenType.pencil), true);
      });

      test('should support eraser', () {
        expect(renderer.supportsPenStyle(PenType.eraser), true);
      });
    });

    group('Line Cap Style', () {
      test('should get default round cap', () {
        final cap = renderer.getDefaultLineCap();
        expect(cap, isA<int>());
      });

      test('should get recommended cap for ballpoint', () {
        final cap = renderer.getRecommendedLineCap(PenType.ballpointPen);
        expect(cap, isA<int>());
      });

      test('should get recommended cap for marker', () {
        final cap = renderer.getRecommendedLineCap(PenType.marker);
        expect(cap, isA<int>());
      });
    });

    group('Line Join Style', () {
      test('should get default round join', () {
        final join = renderer.getDefaultLineJoin();
        expect(join, isA<int>());
      });

      test('should get recommended join for ballpoint', () {
        final join = renderer.getRecommendedLineJoin(PenType.ballpointPen);
        expect(join, isA<int>());
      });

      test('should get recommended join for marker', () {
        final join = renderer.getRecommendedLineJoin(PenType.marker);
        expect(join, isA<int>());
      });
    });

    group('Color Conversion', () {
      test('should convert opaque color', () {
        final color = renderer.convertColor(0xFF0000FF); // Blue
        expect(color, isNotNull);
      });

      test('should convert transparent color', () {
        final color = renderer.convertColor(0x800000FF); // Semi-transparent blue
        expect(color, isNotNull);
      });

      test('should handle alpha channel', () {
        final alpha = renderer.extractAlpha(0x80FFFFFF);
        expect(alpha, closeTo(0.5, 0.01)); // 128/255 ≈ 0.5
      });
    });

    group('Bezier Curve Support', () {
      test('should generate bezier curve from points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 50, y: 100),
          DrawingPoint(x: 100, y: 0),
        ];

        final curve = renderer.generateBezierCurve(points);
        expect(curve, isNotNull);
        expect(curve.length, greaterThanOrEqualTo(points.length));
      });

      test('should handle single point', () {
        final points = [DrawingPoint(x: 0, y: 0)];
        final curve = renderer.generateBezierCurve(points);
        expect(curve, points);
      });
    });

    group('Stroke Smoothing', () {
      test('should smooth stroke path', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 5),
          DrawingPoint(x: 20, y: 0),
          DrawingPoint(x: 30, y: 5),
        ];

        final smoothed = renderer.smoothStroke(points);
        expect(smoothed.length, greaterThanOrEqualTo(points.length));
      });

      test('should preserve endpoints', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 50, y: 50),
          DrawingPoint(x: 100, y: 100),
        ];

        final smoothed = renderer.smoothStroke(points);
        expect(smoothed.first.x, points.first.x);
        expect(smoothed.first.y, points.first.y);
        expect(smoothed.last.x, points.last.x);
        expect(smoothed.last.y, points.last.y);
      });
    });

    group('Rendering Options', () {
      test('should create default rendering options', () {
        final options = VectorRenderOptions();

        expect(options.smoothStrokes, true);
        expect(options.antialiasing, true);
        expect(options.optimizePaths, true);
      });

      test('should create custom rendering options', () {
        final options = VectorRenderOptions(
          smoothStrokes: false,
          antialiasing: false,
          optimizePaths: false,
        );

        expect(options.smoothStrokes, false);
        expect(options.antialiasing, false);
        expect(options.optimizePaths, false);
      });
    });

    group('Path Optimization', () {
      test('should simplify path', () {
        final points = List.generate(100, (i) => DrawingPoint(x: i * 1.0, y: 0));
        final simplified = renderer.simplifyPath(points, tolerance: 1.0);

        expect(simplified.length, lessThan(points.length));
      });

      test('should preserve essential points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 50, y: 100), // Peak
          DrawingPoint(x: 100, y: 0),
        ];

        final simplified = renderer.simplifyPath(points, tolerance: 5.0);
        expect(simplified.length, greaterThanOrEqualTo(3));
      });
    });

    group('Performance Metrics', () {
      test('should estimate rendering complexity', () {
        final stroke = Stroke(
          id: 's1',
          points: List.generate(1000, (i) => DrawingPoint(x: i * 1.0, y: 0)),
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
        );

        final complexity = renderer.estimateComplexity(stroke);
        expect(complexity, greaterThan(0));
      });

      test('should recommend optimization', () {
        final stroke = Stroke(
          id: 's1',
          points: List.generate(10000, (i) => DrawingPoint(x: i * 1.0, y: 0)),
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
        );

        expect(renderer.shouldOptimize(stroke), true);
      });
    });
  });
}
