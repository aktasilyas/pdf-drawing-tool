import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/rendering/tiles/element_bounds.dart';

/// One visible element of an [ElementScene] in paint order.
class SceneEntry {
  const SceneEntry(this.id, this.element);

  final String id;

  /// A [Stroke], [Shape], [ImageElement] or [TextElement].
  final Object element;

  /// Inflated page-space bounds of [element].
  Rect get bounds => switch (element) {
        final Stroke s => strokeBounds(s),
        final Shape s => shapeBounds(s),
        final ImageElement i => imageBounds(i),
        final TextElement t => textBounds(t),
        _ => Rect.zero,
      };
}

/// Immutable snapshot of the committed content of one (page, layer).
///
/// [entries] resolves z-order exactly like `ElementSceneRenderer`: ids in
/// [elementOrder] first, then elements missing from it sorted by id (or, with
/// an empty [elementOrder], strokes, shapes, then images/texts by id).
class ElementScene {
  ElementScene({
    this.strokes = const [],
    this.shapes = const [],
    this.images = const [],
    this.texts = const [],
    this.elementOrder = const [],
    this.excludedIds = const {},
    this.pixelEraserPreview = const {},
    this.strokeEraserPreview = const {},
  });

  final List<Stroke> strokes;
  final List<Shape> shapes;
  final List<ImageElement> images;
  final List<TextElement> texts;
  final List<String> elementOrder;

  /// Ids hidden from the cached layer (e.g. selected elements drawn elsewhere).
  final Set<String> excludedIds;

  /// Stroke id -> point indices hidden by the pixel eraser preview.
  final Map<String, List<int>> pixelEraserPreview;

  /// Stroke ids hidden by the stroke eraser preview.
  final Set<String> strokeEraserPreview;

  /// Visible elements in paint order. Computed once, O(n).
  late final List<SceneEntry> entries = _buildEntries();

  /// Visible elements by id.
  late final Map<String, SceneEntry> byId = {
    for (final e in entries) e.id: e,
  };

  List<SceneEntry> _buildEntries() {
    bool visible(String id) => !excludedIds.contains(id);
    final strokeMap = <String, Object>{
      for (final s in strokes)
        if (visible(s.id) && !strokeEraserPreview.contains(s.id)) s.id: s,
    };
    final shapeMap = <String, Object>{
      for (final s in shapes)
        if (visible(s.id)) s.id: s,
    };
    final imageMap = <String, Object>{
      for (final i in images)
        if (visible(i.id)) i.id: i,
    };
    final textMap = <String, Object>{
      for (final t in texts)
        if (visible(t.id)) t.id: t,
    };

    final result = <SceneEntry>[];
    if (elementOrder.isNotEmpty) {
      final listed = <String>{};
      for (final id in elementOrder) {
        listed.add(id);
        final e = strokeMap[id] ?? shapeMap[id] ?? imageMap[id] ?? textMap[id];
        if (e != null) result.add(SceneEntry(id, e));
      }
      final rest = <SceneEntry>[
        for (final m in [strokeMap, shapeMap, imageMap, textMap])
          for (final e in m.entries)
            if (!listed.contains(e.key)) SceneEntry(e.key, e.value),
      ]..sort((a, b) => a.id.compareTo(b.id));
      result.addAll(rest);
    } else {
      for (final m in [strokeMap, shapeMap]) {
        for (final e in m.entries) {
          result.add(SceneEntry(e.key, e.value));
        }
      }
      final objects = <SceneEntry>[
        for (final m in [imageMap, textMap])
          for (final e in m.entries) SceneEntry(e.key, e.value),
      ]..sort((a, b) => a.id.compareTo(b.id));
      result.addAll(objects);
    }
    return result;
  }
}
