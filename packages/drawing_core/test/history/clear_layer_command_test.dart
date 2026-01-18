import 'package:test/test.dart';
import 'package:drawing_core/src/history/clear_layer_command.dart';
import 'package:drawing_core/src/models/document.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/models/drawing_point.dart';

void main() {
  group('ClearLayerCommand', () {
    test('execute clears all content from layer', () {
      final stroke = Stroke(
        id: 'test',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 10, y: 10, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final document = DrawingDocument.empty('Test').copyWith(
        layers: [Layer.empty('Layer 1').copyWith(strokes: [stroke])],
      );
      
      final command = ClearLayerCommand(layerIndex: 0);
      final result = command.execute(document);
      
      expect(result.layers[0].strokes, isEmpty);
    });
    
    test('undo restores original content', () {
      final stroke = Stroke(
        id: 'test',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 10, y: 10, pressure: 1.0, timestamp: 1),
        ],
        style: StrokeStyle(thickness: 2.0, color: 0xFF000000),
        createdAt: DateTime.now(),
      );
      
      final document = DrawingDocument.empty('Test').copyWith(
        layers: [Layer.empty('Layer 1').copyWith(strokes: [stroke])],
      );
      
      final command = ClearLayerCommand(layerIndex: 0);
      final clearedDoc = command.execute(document);
      final restoredDoc = command.undo(clearedDoc);
      
      expect(restoredDoc.layers[0].strokes.length, equals(1));
      expect(restoredDoc.layers[0].strokes.first.id, equals('test'));
    });
    
    test('handles invalid layer index gracefully', () {
      final document = DrawingDocument.empty('Test');
      
      final command = ClearLayerCommand(layerIndex: 99);
      final result = command.execute(document);
      
      expect(result, equals(document));
    });
  });
}
