import 'package:drawing_core/drawing_core.dart';

/// Command to change the color of selected strokes.
///
/// Updates `style.color` on each selected stroke.
/// Caches old colors for undo support.
class ChangeSelectionStyleCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to update.
  final List<String> strokeIds;

  /// New color value (ARGB32 int).
  final int newColor;

  /// Cached old colors for undo, keyed by stroke ID.
  final Map<String, int> _oldColors = {};

  ChangeSelectionStyleCommand({
    required this.layerIndex,
    required this.strokeIds,
    required this.newColor,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    _oldColors.clear();

    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      _oldColors[id] = stroke.style.color;

      final newStyle = stroke.style.copyWith(color: newColor);
      layer = layer.updateStroke(stroke.copyWith(style: newStyle));
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    for (final entry in _oldColors.entries) {
      final idx = layer.strokes.indexWhere((s) => s.id == entry.key);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      final oldStyle = stroke.style.copyWith(color: entry.value);
      layer = layer.updateStroke(stroke.copyWith(style: oldStyle));
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description => 'Change color of ${strokeIds.length} stroke(s)';
}
