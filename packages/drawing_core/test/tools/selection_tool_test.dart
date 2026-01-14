import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

/// Mock implementation of SelectionTool for testing
class MockSelectionTool implements SelectionTool {
  final List<DrawingPoint> _path = [];
  bool _isSelecting = false;

  @override
  void startSelection(DrawingPoint point) {
    _path.clear();
    _path.add(point);
    _isSelecting = true;
  }

  @override
  void updateSelection(DrawingPoint point) {
    if (_isSelecting) {
      _path.add(point);
    }
  }

  @override
  Selection? endSelection(List<Stroke> strokes, [List<Shape> shapes = const []]) {
    if (!_isSelecting || _path.isEmpty) {
      _isSelecting = false;
      return null;
    }

    _isSelecting = false;

    // Simple mock: return selection with all strokes and shapes
    if (strokes.isEmpty && shapes.isEmpty) return null;

    return Selection.create(
      type: selectionType,
      selectedStrokeIds: strokes.map((s) => s.id).toList(),
      selectedShapeIds: shapes.map((s) => s.id).toList(),
      bounds: BoundingBox(
        left: _path.map((p) => p.x).reduce((a, b) => a < b ? a : b),
        top: _path.map((p) => p.y).reduce((a, b) => a < b ? a : b),
        right: _path.map((p) => p.x).reduce((a, b) => a > b ? a : b),
        bottom: _path.map((p) => p.y).reduce((a, b) => a > b ? a : b),
      ),
      lassoPath: List.from(_path),
    );
  }

  @override
  void cancelSelection() {
    _path.clear();
    _isSelecting = false;
  }

  @override
  bool get isSelecting => _isSelecting;

  @override
  List<DrawingPoint> get currentPath => List.unmodifiable(_path);

  @override
  SelectionType get selectionType => SelectionType.lasso;
}

void main() {
  group('SelectionTool', () {
    test('SelectionTool abstract class exists', () {
      // Abstract class existence check
      expect(SelectionTool, isNotNull);
    });

    test('SelectionType enum has expected values', () {
      expect(SelectionType.values, contains(SelectionType.lasso));
      expect(SelectionType.values, contains(SelectionType.rectangle));
      expect(SelectionType.values.length, equals(2));
    });
  });

  group('MockSelectionTool', () {
    late MockSelectionTool tool;

    setUp(() {
      tool = MockSelectionTool();
    });

    test('initial state is not selecting', () {
      expect(tool.isSelecting, isFalse);
      expect(tool.currentPath, isEmpty);
    });

    test('startSelection begins selection', () {
      tool.startSelection(DrawingPoint(x: 10, y: 20));

      expect(tool.isSelecting, isTrue);
      expect(tool.currentPath.length, equals(1));
      expect(tool.currentPath.first.x, equals(10));
      expect(tool.currentPath.first.y, equals(20));
    });

    test('updateSelection adds points', () {
      tool.startSelection(DrawingPoint(x: 0, y: 0));
      tool.updateSelection(DrawingPoint(x: 50, y: 50));
      tool.updateSelection(DrawingPoint(x: 100, y: 100));

      expect(tool.currentPath.length, equals(3));
    });

    test('updateSelection does nothing when not selecting', () {
      tool.updateSelection(DrawingPoint(x: 50, y: 50));

      expect(tool.currentPath, isEmpty);
    });

    test('endSelection returns null when no strokes', () {
      tool.startSelection(DrawingPoint(x: 0, y: 0));
      tool.updateSelection(DrawingPoint(x: 100, y: 100));

      final selection = tool.endSelection([]);

      expect(selection, isNull);
      expect(tool.isSelecting, isFalse);
    });

    test('endSelection returns Selection with strokes', () {
      tool.startSelection(DrawingPoint(x: 0, y: 0));
      tool.updateSelection(DrawingPoint(x: 100, y: 100));

      final stroke = Stroke.create(style: StrokeStyle.pen())
          .addPoint(DrawingPoint(x: 50, y: 50));

      final selection = tool.endSelection([stroke]);

      expect(selection, isNotNull);
      expect(selection!.selectedStrokeIds, contains(stroke.id));
      expect(selection.type, equals(SelectionType.lasso));
      expect(tool.isSelecting, isFalse);
    });

    test('cancelSelection clears state', () {
      tool.startSelection(DrawingPoint(x: 0, y: 0));
      tool.updateSelection(DrawingPoint(x: 100, y: 100));

      tool.cancelSelection();

      expect(tool.isSelecting, isFalse);
      expect(tool.currentPath, isEmpty);
    });

    test('selectionType returns lasso', () {
      expect(tool.selectionType, equals(SelectionType.lasso));
    });
  });
}
