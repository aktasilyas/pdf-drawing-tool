import 'package:drawing_core/drawing_core.dart';

/// Command to change the color of selected strokes, shapes and text elements.
///
/// Updates `style.color` on each selected stroke and shape (plus a shape's
/// `fillColor`, keeping its alpha) and `color` on each text.
/// Caches old colors for undo support.
class ChangeSelectionStyleCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to update.
  final List<String> strokeIds;

  /// IDs of text elements to update.
  final List<String> textIds;

  /// IDs of shapes to update.
  final List<String> shapeIds;

  /// New color value (ARGB32 int).
  final int newColor;

  /// Cached old stroke colors for undo, keyed by stroke ID.
  final Map<String, int> _oldStrokeColors = {};

  /// Cached old shapes for undo, keyed by shape ID.
  final Map<String, Shape> _oldShapes = {};

  /// Cached old text colors for undo, keyed by text ID.
  final Map<String, int> _oldTextColors = {};

  ChangeSelectionStyleCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.textIds = const [],
    this.shapeIds = const [],
    required this.newColor,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    _oldStrokeColors.clear();
    _oldTextColors.clear();
    _oldShapes.clear();

    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      _oldStrokeColors[id] = stroke.style.color;

      final newStyle = stroke.style.copyWith(color: newColor);
      layer = layer.updateStroke(stroke.copyWith(style: newStyle));
    }

    for (final id in shapeIds) {
      final idx = layer.shapes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final shape = layer.shapes[idx];
      _oldShapes[id] = shape;
      layer = _replaceShape(layer, idx, _recolor(shape));
    }

    for (final id in textIds) {
      final text = layer.getTextById(id);
      if (text == null) continue;

      _oldTextColors[id] = text.color;
      layer = layer.updateText(text.copyWith(color: newColor));
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    for (final entry in _oldStrokeColors.entries) {
      final idx = layer.strokes.indexWhere((s) => s.id == entry.key);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      final oldStyle = stroke.style.copyWith(color: entry.value);
      layer = layer.updateStroke(stroke.copyWith(style: oldStyle));
    }

    for (final old in _oldShapes.values) {
      final idx = layer.shapes.indexWhere((s) => s.id == old.id);
      if (idx == -1) continue;

      layer = _replaceShape(layer, idx, old);
    }

    for (final entry in _oldTextColors.entries) {
      final text = layer.getTextById(entry.key);
      if (text == null) continue;

      layer = layer.updateText(text.copyWith(color: entry.value));
    }

    return document.updateLayer(layerIndex, layer);
  }

  Shape _recolor(Shape shape) {
    final fill = shape.fillColor;
    return shape.copyWith(
      style: shape.style.copyWith(color: newColor),
      fillColor:
          fill == null ? null : (fill & 0xFF000000) | (newColor & 0xFFFFFF),
    );
  }

  Layer _replaceShape(Layer layer, int index, Shape shape) {
    final shapes = List<Shape>.of(layer.shapes);
    shapes[index] = shape;
    return layer.copyWith(shapes: shapes);
  }

  @override
  String get description =>
      'Change color of ${strokeIds.length + shapeIds.length + textIds.length} '
      'element(s)';
}
