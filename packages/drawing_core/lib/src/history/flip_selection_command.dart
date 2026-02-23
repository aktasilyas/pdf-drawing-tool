import 'package:drawing_core/drawing_core.dart';

/// Axis for flipping elements.
enum FlipAxis {
  /// Flip horizontally (mirror across vertical center line).
  horizontal,

  /// Flip vertically (mirror across horizontal center line).
  vertical,
}

/// Command to flip selected strokes and shapes around a center point.
///
/// Self-inverse: flipping twice restores original positions.
class FlipSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to flip.
  final List<String> strokeIds;

  /// IDs of shapes to flip.
  final List<String> shapeIds;

  /// IDs of images to flip.
  final List<String> imageIds;

  /// IDs of texts to flip.
  final List<String> textIds;

  /// Center X of the selection bounds.
  final double centerX;

  /// Center Y of the selection bounds.
  final double centerY;

  /// Axis to flip around.
  final FlipAxis axis;

  FlipSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    this.imageIds = const [],
    this.textIds = const [],
    required this.centerX,
    required this.centerY,
    required this.axis,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    return _applyFlip(document);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    // Flip is self-inverse
    return _applyFlip(document);
  }

  DrawingDocument _applyFlip(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      final flippedPoints = stroke.points.map((p) {
        return DrawingPoint(
          x: axis == FlipAxis.horizontal ? 2 * centerX - p.x : p.x,
          y: axis == FlipAxis.vertical ? 2 * centerY - p.y : p.y,
          pressure: p.pressure,
          tilt: p.tilt,
          timestamp: p.timestamp,
        );
      }).toList();
      layer = layer.updateStroke(stroke.copyWith(points: flippedPoints));
    }

    for (final id in shapeIds) {
      final shape = layer.getShapeById(id);
      if (shape == null) continue;

      final sp = shape.startPoint;
      final ep = shape.endPoint;

      layer = layer.updateShape(shape.copyWith(
        startPoint: DrawingPoint(
          x: axis == FlipAxis.horizontal ? 2 * centerX - sp.x : sp.x,
          y: axis == FlipAxis.vertical ? 2 * centerY - sp.y : sp.y,
          pressure: sp.pressure,
        ),
        endPoint: DrawingPoint(
          x: axis == FlipAxis.horizontal ? 2 * centerX - ep.x : ep.x,
          y: axis == FlipAxis.vertical ? 2 * centerY - ep.y : ep.y,
          pressure: ep.pressure,
        ),
      ));
    }

    // Flip images
    for (final id in imageIds) {
      final image = layer.getImageById(id);
      if (image == null) continue;

      final imgCx = image.x + image.width / 2;
      final imgCy = image.y + image.height / 2;
      final newCx = axis == FlipAxis.horizontal ? 2 * centerX - imgCx : imgCx;
      final newCy = axis == FlipAxis.vertical ? 2 * centerY - imgCy : imgCy;
      final newRot = axis == FlipAxis.horizontal
          ? -image.rotation
          : image.rotation;
      layer = layer.updateImage(image.copyWith(
        x: newCx - image.width / 2,
        y: newCy - image.height / 2,
        rotation: newRot,
      ));
    }

    // Flip texts (position only)
    for (final id in textIds) {
      final text = layer.getTextById(id);
      if (text == null) continue;

      final newX = axis == FlipAxis.horizontal ? 2 * centerX - text.x : text.x;
      final newY = axis == FlipAxis.vertical ? 2 * centerY - text.y : text.y;
      layer = layer.updateText(text.copyWith(x: newX, y: newY));
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Flip ${axis == FlipAxis.horizontal ? 'horizontal' : 'vertical'}'
      ' ${strokeIds.length + shapeIds.length + imageIds.length + textIds.length} element(s)';
}
