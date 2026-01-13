import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('RectSelectionTool', () {
    late RectSelectionTool tool;

    setUp(() {
      tool = RectSelectionTool();
    });

    group('selection lifecycle', () {
      test('initial state is not selecting', () {
        expect(tool.isSelecting, isFalse);
        expect(tool.currentPath, isEmpty);
        expect(tool.currentBounds, isNull);
      });

      test('startSelection begins selection', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));

        expect(tool.isSelecting, isTrue);
        expect(tool.currentBounds, isNotNull);
      });

      test('updateSelection updates end point', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        expect(tool.currentBounds?.right, equals(100));
        expect(tool.currentBounds?.bottom, equals(100));
      });

      test('updateSelection does nothing when not selecting', () {
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        expect(tool.currentBounds, isNull);
      });

      test('cancelSelection clears state', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));
        tool.cancelSelection();

        expect(tool.isSelecting, isFalse);
        expect(tool.currentPath, isEmpty);
        expect(tool.currentBounds, isNull);
      });
    });

    group('currentPath', () {
      test('returns empty when not selecting', () {
        expect(tool.currentPath, isEmpty);
      });

      test('returns rectangle path with 5 points', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        final path = tool.currentPath;

        expect(path.length, equals(5)); // 4 corners + closing
        expect(path.first.x, equals(path.last.x));
        expect(path.first.y, equals(path.last.y));
      });

      test('path corners are correct', () {
        tool.startSelection(DrawingPoint(x: 10, y: 20));
        tool.updateSelection(DrawingPoint(x: 110, y: 120));

        final path = tool.currentPath;

        // Top-left
        expect(path[0].x, equals(10));
        expect(path[0].y, equals(20));
        // Top-right
        expect(path[1].x, equals(110));
        expect(path[1].y, equals(20));
        // Bottom-right
        expect(path[2].x, equals(110));
        expect(path[2].y, equals(120));
        // Bottom-left
        expect(path[3].x, equals(10));
        expect(path[3].y, equals(120));
      });
    });

    group('currentBounds', () {
      test('returns null when not selecting', () {
        expect(tool.currentBounds, isNull);
      });

      test('returns correct bounds', () {
        tool.startSelection(DrawingPoint(x: 10, y: 20));
        tool.updateSelection(DrawingPoint(x: 110, y: 120));

        final bounds = tool.currentBounds!;

        expect(bounds.left, equals(10));
        expect(bounds.top, equals(20));
        expect(bounds.right, equals(110));
        expect(bounds.bottom, equals(120));
      });

      test('handles inverted rectangle', () {
        // Right-to-left drag
        tool.startSelection(DrawingPoint(x: 100, y: 100));
        tool.updateSelection(DrawingPoint(x: 0, y: 0));

        final bounds = tool.currentBounds!;

        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.right, equals(100));
        expect(bounds.bottom, equals(100));
      });
    });

    group('endSelection', () {
      test('returns null for small selection', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 2, y: 2));

        final result = tool.endSelection([]);

        expect(result, isNull);
        expect(tool.isSelecting, isFalse);
      });

      test('returns null when no strokes provided', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        final result = tool.endSelection([]);

        expect(result, isNull);
      });

      test('returns null when no strokes selected', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        // Stroke outside selection
        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 200, y: 200))
            .addPoint(DrawingPoint(x: 300, y: 300));

        final result = tool.endSelection([stroke]);

        expect(result, isNull);
      });

      test('returns selection when stroke is inside rectangle', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50))
            .addPoint(DrawingPoint(x: 60, y: 60));

        final result = tool.endSelection([stroke]);

        expect(result, isNotNull);
        expect(result!.selectedStrokeIds, contains(stroke.id));
        expect(result.type, equals(SelectionType.rectangle));
      });

      test('handles inverted rectangle (right-to-left drag)', () {
        tool.startSelection(DrawingPoint(x: 100, y: 100));
        tool.updateSelection(DrawingPoint(x: 0, y: 0));

        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50));

        final result = tool.endSelection([stroke]);

        expect(result, isNotNull);
        expect(result!.selectedStrokeIds, contains(stroke.id));
      });

      test('selects stroke that partially intersects', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 50, y: 50));

        // Stroke partially inside, partially outside
        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 25, y: 25))
            .addPoint(DrawingPoint(x: 100, y: 100));

        final result = tool.endSelection([stroke]);

        expect(result, isNotNull);
        expect(result!.selectedStrokeIds, contains(stroke.id));
      });

      test('selects multiple strokes', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 200, y: 200));

        final stroke1 = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50));

        final stroke2 = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 100, y: 100));

        final result = tool.endSelection([stroke1, stroke2]);

        expect(result, isNotNull);
        expect(result!.count, equals(2));
      });

      test('calculates correct bounds for selected strokes', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 500, y: 500));

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

      test('clears state after selection', () {
        tool.startSelection(DrawingPoint(x: 0, y: 0));
        tool.updateSelection(DrawingPoint(x: 100, y: 100));

        final stroke = Stroke.create(style: StrokeStyle.pen())
            .addPoint(DrawingPoint(x: 50, y: 50));

        tool.endSelection([stroke]);

        expect(tool.isSelecting, isFalse);
        expect(tool.currentPath, isEmpty);
        expect(tool.currentBounds, isNull);
      });
    });

    group('selectionType', () {
      test('returns rectangle type', () {
        expect(tool.selectionType, equals(SelectionType.rectangle));
      });
    });
  });
}
