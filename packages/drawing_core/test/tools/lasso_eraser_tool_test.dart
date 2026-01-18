import 'package:test/test.dart';
import 'package:drawing_core/src/tools/lasso_eraser_tool.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

void main() {
  group('LassoEraserTool', () {
    late LassoEraserTool lasso;
    
    setUp(() {
      lasso = LassoEraserTool();
    });
    
    test('collects lasso points', () {
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(100, 0);
      lasso.onPointerMove(100, 100);
      lasso.onPointerMove(0, 100);
      
      expect(lasso.lassoPoints.length, equals(4));
      expect(lasso.isActive, isTrue);
    });
    
    test('finds segments inside lasso', () {
      // Create a square lasso
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(100, 0);
      lasso.onPointerMove(100, 100);
      lasso.onPointerMove(0, 100);
      
      // Stroke with segment inside
      final insideStroke = Stroke(
        id: 'inside',
        points: [
          DrawingPoint(x: 50, y: 50, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 60, y: 60, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      // Stroke completely outside
      final outsideStroke = Stroke(
        id: 'outside',
        points: [
          DrawingPoint(x: 200, y: 200, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 210, y: 210, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final result = lasso.onPointerUp([insideStroke, outsideStroke]);
      
      expect(result.affectedSegments.keys, contains('inside'));
      expect(result.affectedSegments.keys, isNot(contains('outside')));
      expect(result.affectedStrokes.length, equals(1));
    });
    
    test('returns empty for small lasso', () {
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(1, 1);
      
      final result = lasso.onPointerUp([]);
      
      expect(result.affectedSegments, isEmpty);
      expect(result.affectedStrokes, isEmpty);
    });
    
    test('clears on cancel', () {
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(100, 100);
      
      lasso.cancel();
      
      expect(lasso.isActive, isFalse);
      expect(lasso.lassoPoints, isEmpty);
    });
    
    test('bounding box pre-filter works', () {
      // Small lasso in corner
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(10, 0);
      lasso.onPointerMove(10, 10);
      lasso.onPointerMove(0, 10);
      
      // Stroke far away
      final farStroke = Stroke(
        id: 'far',
        points: [
          DrawingPoint(x: 1000, y: 1000, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 1010, y: 1010, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final result = lasso.onPointerUp([farStroke]);
      
      expect(result.affectedSegments, isEmpty);
    });
    
    test('detects segments crossing lasso boundary', () {
      // Create a square lasso
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(100, 0);
      lasso.onPointerMove(100, 100);
      lasso.onPointerMove(0, 100);
      
      // Stroke that crosses lasso - only middle segment should be affected
      final crossingStroke = Stroke(
        id: 'crossing',
        points: [
          DrawingPoint(x: -50, y: 50, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 50, y: 50, pressure: 1.0, timestamp: 1), // Inside
          DrawingPoint(x: 150, y: 50, pressure: 1.0, timestamp: 2),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final result = lasso.onPointerUp([crossingStroke]);
      
      expect(result.affectedSegments.keys, contains('crossing'));
      expect(result.affectedSegments['crossing'], isNotEmpty);
    });
    
    test('handles multiple strokes inside lasso', () {
      // Create a square lasso
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(100, 0);
      lasso.onPointerMove(100, 100);
      lasso.onPointerMove(0, 100);
      
      final stroke1 = Stroke(
        id: 'stroke1',
        points: [
          DrawingPoint(x: 25, y: 25, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 35, y: 35, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final stroke2 = Stroke(
        id: 'stroke2',
        points: [
          DrawingPoint(x: 75, y: 75, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 85, y: 85, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final result = lasso.onPointerUp([stroke1, stroke2]);
      
      expect(result.affectedSegments.length, equals(2));
      expect(result.affectedSegments.keys, contains('stroke1'));
      expect(result.affectedSegments.keys, contains('stroke2'));
      expect(result.affectedStrokes.length, equals(2));
    });
  });
}
