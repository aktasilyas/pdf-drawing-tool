import 'package:drawing_core/src/internal.dart';

/// Command for pixel-based erasing (segment removal).
/// Splits strokes at erased segments for undo support.
class ErasePointsCommand implements DrawingCommand {
  ErasePointsCommand({
    required this.layerIndex,
    required this.originalStrokes,
    required this.resultingStrokes,
  });
  
  final int layerIndex;

  /// Original strokes before erasing
  final List<Stroke> originalStrokes;

  /// Resulting strokes after erasing (split strokes)
  final List<Stroke> resultingStrokes;

  /// Cached elementOrder before execute (for undo z-order restore).
  List<String> _originalElementOrder = const [];
  
  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];

    // Cache elementOrder before modification (for undo z-order restore)
    _originalElementOrder = List<String>.from(layer.elementOrder);

    // Remove original strokes
    var newStrokes = List<Stroke>.from(layer.strokes);
    for (final original in originalStrokes) {
      newStrokes.removeWhere((s) => s.id == original.id);
    }

    // Add resulting strokes (split pieces)
    newStrokes.addAll(resultingStrokes);

    // Update elementOrder: replace each original ID with its split IDs in-place
    final originalIds = {for (final s in originalStrokes) s.id};
    final splitMap = <String, List<String>>{};
    for (final original in originalStrokes) {
      splitMap[original.id] = resultingStrokes
          .where((s) => s.id.startsWith('${original.id}_split_'))
          .map((s) => s.id)
          .toList();
    }

    final newElementOrder = <String>[];
    for (final id in layer.elementOrder) {
      if (originalIds.contains(id)) {
        final splits = splitMap[id];
        if (splits != null && splits.isNotEmpty) {
          newElementOrder.addAll(splits);
        }
      } else {
        newElementOrder.add(id);
      }
    }

    final updatedLayer = layer.copyWith(
      strokes: newStrokes,
      elementOrder: newElementOrder,
    );

    return document.updateLayer(layerIndex, updatedLayer);
  }
  
  @override
  DrawingDocument undo(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];

    // Remove resulting strokes
    var newStrokes = List<Stroke>.from(layer.strokes);
    for (final result in resultingStrokes) {
      newStrokes.removeWhere((s) => s.id == result.id);
    }

    // Restore original strokes
    newStrokes.addAll(originalStrokes);

    // Restore original elementOrder
    final updatedLayer = layer.copyWith(
      strokes: newStrokes,
      elementOrder: _originalElementOrder.isNotEmpty
          ? _originalElementOrder
          : null,
    );

    return document.updateLayer(layerIndex, updatedLayer);
  }
  
  @override
  String get description => 'Erase points (${originalStrokes.length} strokes affected)';
}

/// Utility to split stroke at erased segments
class StrokeSplitter {
  /// Split a stroke by removing specified segments
  /// Returns list of new strokes (pieces that remain)
  static List<Stroke> splitStroke(
    Stroke stroke,
    List<int> segmentIndicesToRemove,
  ) {
    if (segmentIndicesToRemove.isEmpty) {
      return [stroke];
    }
    
    final points = stroke.points;
    if (points.length < 2) {
      return [];
    }
    
    // Sort indices for easier processing
    final sortedIndices = segmentIndicesToRemove.toSet().toList()..sort();
    
    final pieces = <List<DrawingPoint>>[];
    var currentPiece = <DrawingPoint>[];
    
    for (int i = 0; i < points.length; i++) {
      final segmentIndex = i > 0 ? i - 1 : 0;
      
      if (i == 0 || !sortedIndices.contains(segmentIndex)) {
        currentPiece.add(points[i]);
      } else {
        // Segment is removed, start new piece
        if (currentPiece.length >= 2) {
          pieces.add(currentPiece);
        }
        currentPiece = [points[i]];
      }
    }
    
    // Add last piece
    if (currentPiece.length >= 2) {
      pieces.add(currentPiece);
    }
    
    // Convert pieces to strokes
    return pieces.asMap().entries.map((entry) {
      return Stroke(
        id: '${stroke.id}_split_${entry.key}',
        points: entry.value,
        style: stroke.style,
        createdAt: stroke.createdAt,
      );
    }).toList();
  }
  
  /// Split multiple strokes based on segment hits
  /// Returns map of original stroke -> resulting strokes
  static Map<Stroke, List<Stroke>> splitStrokes(
    List<Stroke> strokes,
    Map<String, List<int>> affectedSegments,
  ) {
    final result = <Stroke, List<Stroke>>{};
    
    for (final stroke in strokes) {
      final segments = affectedSegments[stroke.id];
      if (segments != null && segments.isNotEmpty) {
        result[stroke] = splitStroke(stroke, segments);
      }
    }
    
    return result;
  }
}
