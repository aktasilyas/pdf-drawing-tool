import 'package:drawing_core/drawing_core.dart';

/// Command to move selected strokes by a delta.
///
/// This command moves all points of the selected strokes
/// by the specified deltaX and deltaY values.
///
/// Supports undo by moving in the opposite direction.
class MoveSelectionCommand implements DrawingCommand {
  /// The layer index containing the strokes.
  final int layerIndex;

  /// IDs of strokes to move.
  final List<String> strokeIds;

  /// Horizontal movement delta.
  final double deltaX;

  /// Vertical movement delta.
  final double deltaY;

  /// Creates a move selection command.
  MoveSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    required this.deltaX,
    required this.deltaY,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    for (final id in strokeIds) {
      final strokeIndex = layer.strokes.indexWhere((s) => s.id == id);
      if (strokeIndex == -1) continue;

      final stroke = layer.strokes[strokeIndex];

      // Move all points by delta
      final movedPoints = stroke.points
          .map((p) => DrawingPoint(
                x: p.x + deltaX,
                y: p.y + deltaY,
                pressure: p.pressure,
                tilt: p.tilt,
                timestamp: p.timestamp,
              ))
          .toList();

      final movedStroke = stroke.copyWith(points: movedPoints);
      layer = layer.updateStroke(movedStroke);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    // Move in the opposite direction
    return MoveSelectionCommand(
      layerIndex: layerIndex,
      strokeIds: strokeIds,
      deltaX: -deltaX,
      deltaY: -deltaY,
    ).execute(document);
  }

  @override
  String get description => 'Move ${strokeIds.length} element(s)';
}
