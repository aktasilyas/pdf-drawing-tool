import 'package:drawing_core/drawing_core.dart';

/// Command to change the color of selected strokes and text elements.
///
/// Updates `style.color` on each selected stroke and `color` on each text.
/// Caches old colors for undo support.
class ChangeSelectionStyleCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to update.
  final List<String> strokeIds;

  /// IDs of text elements to update.
  final List<String> textIds;

  /// New color value (ARGB32 int).
  final int newColor;

  /// Cached old stroke colors for undo, keyed by stroke ID.
  final Map<String, int> _oldStrokeColors = {};

  /// Cached old text colors for undo, keyed by text ID.
  final Map<String, int> _oldTextColors = {};

  ChangeSelectionStyleCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.textIds = const [],
    required this.newColor,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    _oldStrokeColors.clear();
    _oldTextColors.clear();

    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      _oldStrokeColors[id] = stroke.style.color;

      final newStyle = stroke.style.copyWith(color: newColor);
      layer = layer.updateStroke(stroke.copyWith(style: newStyle));
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

    for (final entry in _oldTextColors.entries) {
      final text = layer.getTextById(entry.key);
      if (text == null) continue;

      layer = layer.updateText(text.copyWith(color: entry.value));
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Change color of ${strokeIds.length + textIds.length} element(s)';
}
