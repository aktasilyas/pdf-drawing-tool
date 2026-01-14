import 'package:drawing_core/drawing_core.dart';

/// Command to move selected strokes and shapes by a delta.
///
/// This command moves all points of the selected strokes
/// and the start/end points of selected shapes
/// by the specified deltaX and deltaY values.
///
/// Supports undo by moving in the opposite direction.
class MoveSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to move.
  final List<String> strokeIds;

  /// IDs of shapes to move.
  final List<String> shapeIds;

  /// Horizontal movement delta.
  final double deltaX;

  /// Vertical movement delta.
  final double deltaY;

  /// Creates a move selection command.
  MoveSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    required this.deltaX,
    required this.deltaY,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    // Move strokes
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

    // Move shapes
    for (final id in shapeIds) {
      final shape = layer.getShapeById(id);
      if (shape == null) continue;

      final movedShape = shape.copyWith(
        startPoint: DrawingPoint(
          x: shape.startPoint.x + deltaX,
          y: shape.startPoint.y + deltaY,
          pressure: shape.startPoint.pressure,
        ),
        endPoint: DrawingPoint(
          x: shape.endPoint.x + deltaX,
          y: shape.endPoint.y + deltaY,
          pressure: shape.endPoint.pressure,
        ),
      );
      layer = layer.updateShape(movedShape);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    // Move in the opposite direction
    return MoveSelectionCommand(
      layerIndex: layerIndex,
      strokeIds: strokeIds,
      shapeIds: shapeIds,
      deltaX: -deltaX,
      deltaY: -deltaY,
    ).execute(document);
  }

  @override
  String get description =>
      'Move ${strokeIds.length + shapeIds.length} element(s)';
}
