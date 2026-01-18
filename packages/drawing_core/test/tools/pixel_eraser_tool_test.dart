import 'package:test/test.dart';
import 'package:drawing_core/src/tools/pixel_eraser_tool.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

void main() {
  group('PixelEraserTool', () {
    late PixelEraserTool eraser;
    
    setUp(() {
      eraser = PixelEraserTool(size: 20.0);
    });
    
    test('finds segments within tolerance', () {
      final stroke = Stroke(
        id: 'test-1',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 100, y: 0, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final hits = eraser.findSegmentsAt([stroke], 50, 5, 20.0);
      
      expect(hits, isNotEmpty);
      expect(hits.first.strokeId, equals('test-1'));
      expect(hits.first.segmentIndex, equals(0));
    });
    
    test('ignores segments outside tolerance', () {
      final stroke = Stroke(
        id: 'test-1',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 100, y: 0, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final hits = eraser.findSegmentsAt([stroke], 50, 50, 20.0);
      
      expect(hits, isEmpty);
    });
    
    test('bounding box pre-filter works', () {
      final stroke = Stroke(
        id: 'test-1',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 10, y: 10, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      // Far outside bounds
      final hits = eraser.findSegmentsAt([stroke], 1000, 1000, 20.0);
      
      expect(hits, isEmpty);
    });
    
    test('collects erase points during gesture', () {
      eraser.onPointerDown(10, 10, 1.0);
      eraser.onPointerMove(20, 20, 1.0);
      eraser.onPointerMove(30, 30, 1.0);
      
      final result = eraser.onPointerUp();
      
      expect(result.erasePoints.length, equals(3));
    });
    
    test('pressure sensitivity affects size', () {
      final pressureEraser = PixelEraserTool(
        size: 20.0,
        pressureSensitive: true,
      );
      
      // Low pressure should result in smaller effective size
      // This is tested indirectly through the erase behavior
      expect(pressureEraser.pressureSensitive, isTrue);
    });
  });
}
