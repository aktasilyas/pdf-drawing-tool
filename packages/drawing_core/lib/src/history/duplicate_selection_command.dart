import 'package:drawing_core/drawing_core.dart';

/// Command to duplicate selected strokes and shapes with an offset.
///
/// Clones strokes/shapes with new IDs and applies an offset.
/// Caches new IDs for undo removal.
class DuplicateSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to duplicate.
  final List<String> strokeIds;

  /// IDs of shapes to duplicate.
  final List<String> shapeIds;

  /// IDs of images to duplicate.
  final List<String> imageIds;

  /// IDs of texts to duplicate.
  final List<String> textIds;

  /// Horizontal offset for duplicated items.
  final double offsetX;

  /// Vertical offset for duplicated items.
  final double offsetY;

  /// New stroke IDs created by execute (for post-execute selection update).
  final List<String> newStrokeIds = [];

  /// New shape IDs created by execute (for post-execute selection update).
  final List<String> newShapeIds = [];

  /// New image IDs created by execute (for post-execute selection update).
  final List<String> newImageIds = [];

  /// New text IDs created by execute (for post-execute selection update).
  final List<String> newTextIds = [];

  DuplicateSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    this.imageIds = const [],
    this.textIds = const [],
    this.offsetX = 40.0,
    this.offsetY = 40.0,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    newStrokeIds.clear();
    newShapeIds.clear();
    newImageIds.clear();
    newTextIds.clear();

    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      final movedPoints = stroke.points
          .map((p) => DrawingPoint(
                x: p.x + offsetX,
                y: p.y + offsetY,
                pressure: p.pressure,
                tilt: p.tilt,
                timestamp: p.timestamp,
              ))
          .toList();

      final newStroke = Stroke.create(
        style: stroke.style,
        points: movedPoints,
      );
      newStrokeIds.add(newStroke.id);
      layer = layer.addStroke(newStroke);
    }

    for (final id in shapeIds) {
      final shape = layer.getShapeById(id);
      if (shape == null) continue;

      final newId = DateTime.now().microsecondsSinceEpoch.toString();
      final newShape = Shape(
        id: newId,
        type: shape.type,
        startPoint: DrawingPoint(
          x: shape.startPoint.x + offsetX,
          y: shape.startPoint.y + offsetY,
          pressure: shape.startPoint.pressure,
        ),
        endPoint: DrawingPoint(
          x: shape.endPoint.x + offsetX,
          y: shape.endPoint.y + offsetY,
          pressure: shape.endPoint.pressure,
        ),
        style: shape.style,
        isFilled: shape.isFilled,
        fillColor: shape.fillColor,
      );
      newShapeIds.add(newId);
      layer = layer.addShape(newShape);
    }

    // Duplicate images
    for (final id in imageIds) {
      final image = layer.getImageById(id);
      if (image == null) continue;

      final newImage = ImageElement.create(
        filePath: image.filePath,
        x: image.x + offsetX,
        y: image.y + offsetY,
        width: image.width,
        height: image.height,
        rotation: image.rotation,
      );
      newImageIds.add(newImage.id);
      layer = layer.addImage(newImage);
    }

    // Duplicate texts
    for (final id in textIds) {
      final text = layer.getTextById(id);
      if (text == null) continue;

      final newText = TextElement.create(
        text: text.text,
        x: text.x + offsetX,
        y: text.y + offsetY,
        fontSize: text.fontSize,
        color: text.color,
        fontFamily: text.fontFamily,
        isBold: text.isBold,
        isItalic: text.isItalic,
        isUnderline: text.isUnderline,
        alignment: text.alignment,
      );
      newTextIds.add(newText.id);
      layer = layer.addText(newText);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    for (final id in newStrokeIds) {
      layer = layer.removeStroke(id);
    }
    for (final id in newShapeIds) {
      layer = layer.removeShape(id);
    }
    for (final id in newImageIds) {
      layer = layer.removeImage(id);
    }
    for (final id in newTextIds) {
      layer = layer.removeText(id);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Duplicate ${strokeIds.length + shapeIds.length + imageIds.length + textIds.length} element(s)';
}
