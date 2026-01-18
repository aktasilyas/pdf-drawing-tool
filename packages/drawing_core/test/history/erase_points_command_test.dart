import 'package:test/test.dart';
import 'package:drawing_core/src/history/erase_points_command.dart';
import 'package:drawing_core/src/models/document.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

void main() {
  group('ErasePointsCommand', () {
    test('execute replaces original with split strokes', () {
      final original = Stroke(
        id: 'original',
        points: _createPoints(5),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final split1 = Stroke(
        id: 'original_split_0',
        points: _createPoints(2),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final document = DrawingDocument.empty('Test').copyWith(
        layers: [Layer.empty('Layer 1').copyWith(strokes: [original])],
      );
      
      final command = ErasePointsCommand(
        layerIndex: 0,
        originalStrokes: [original],
        resultingStrokes: [split1],
      );
      
      final result = command.execute(document);
      
      expect(result.layers[0].strokes.length, equals(1));
      expect(result.layers[0].strokes.first.id, equals('original_split_0'));
    });
    
    test('undo restores original strokes', () {
      final original = Stroke(
        id: 'original',
        points: _createPoints(5),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final split1 = Stroke(
        id: 'original_split_0',
        points: _createPoints(2),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final documentAfterErase = DrawingDocument.empty('Test').copyWith(
        layers: [Layer.empty('Layer 1').copyWith(strokes: [split1])],
      );
      
      final command = ErasePointsCommand(
        layerIndex: 0,
        originalStrokes: [original],
        resultingStrokes: [split1],
      );
      
      final result = command.undo(documentAfterErase);
      
      expect(result.layers[0].strokes.length, equals(1));
      expect(result.layers[0].strokes.first.id, equals('original'));
    });
    
    test('handles invalid layer index gracefully', () {
      final document = DrawingDocument.empty('Test');
      
      final command = ErasePointsCommand(
        layerIndex: 99,
        originalStrokes: [],
        resultingStrokes: [],
      );
      
      final result = command.execute(document);
      expect(result, equals(document));
    });
    
    test('description shows affected stroke count', () {
      final original1 = Stroke(
        id: 'original1',
        points: _createPoints(3),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final original2 = Stroke(
        id: 'original2',
        points: _createPoints(3),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final command = ErasePointsCommand(
        layerIndex: 0,
        originalStrokes: [original1, original2],
        resultingStrokes: [],
      );
      
      expect(command.description, contains('2 strokes affected'));
    });
  });
  
  group('StrokeSplitter', () {
    test('splits stroke at removed segments', () {
      final stroke = Stroke(
        id: 'test',
        points: _createPoints(5), // 4 segments: 0-1, 1-2, 2-3, 3-4
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      // Remove middle segment (index 2)
      final pieces = StrokeSplitter.splitStroke(stroke, [2]);
      
      expect(pieces.length, equals(2));
      expect(pieces[0].id, equals('test_split_0'));
      expect(pieces[1].id, equals('test_split_1'));
    });
    
    test('returns empty list when all segments removed', () {
      final stroke = Stroke(
        id: 'test',
        points: _createPoints(2), // 1 segment
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final pieces = StrokeSplitter.splitStroke(stroke, [0]);
      
      // Single point pieces are discarded
      expect(pieces.length, equals(0));
    });
    
    test('returns original when no segments removed', () {
      final stroke = Stroke(
        id: 'test',
        points: _createPoints(5),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final pieces = StrokeSplitter.splitStroke(stroke, []);
      
      expect(pieces.length, equals(1));
      expect(pieces.first.id, equals('test'));
    });
    
    test('handles multiple removed segments', () {
      final stroke = Stroke(
        id: 'test',
        points: _createPoints(7), // 6 segments: 0,1,2,3,4,5
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      // Remove segments 1 and 4
      final pieces = StrokeSplitter.splitStroke(stroke, [1, 4]);
      
      expect(pieces.length, equals(3));
    });
    
    test('preserves stroke style in split pieces', () {
      final style = StrokeStyle(thickness: 5.0, color: 0xFFFF0000);
      final stroke = Stroke(
        id: 'test',
        points: _createPoints(5),
        style: style,
        createdAt: DateTime.now(),
      );
      
      final pieces = StrokeSplitter.splitStroke(stroke, [2]);
      
      for (final piece in pieces) {
        expect(piece.style.thickness, equals(5.0));
        expect(piece.style.color, equals(0xFFFF0000));
      }
    });
    
    test('splitStrokes handles multiple strokes', () {
      final stroke1 = Stroke(
        id: 'stroke1',
        points: _createPoints(5),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final stroke2 = Stroke(
        id: 'stroke2',
        points: _createPoints(4),
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final affectedSegments = {
        'stroke1': [2],
        'stroke2': [1],
      };
      
      final result = StrokeSplitter.splitStrokes([stroke1, stroke2], affectedSegments);
      
      expect(result.length, equals(2));
      expect(result[stroke1]!.length, equals(2));
      expect(result[stroke2]!.length, equals(2));
    });
  });
}

List<DrawingPoint> _createPoints(int count) {
  return List.generate(count, (i) => DrawingPoint(
    x: i * 10.0,
    y: i * 10.0,
    pressure: 1.0,
    timestamp: i,
  ));
}
