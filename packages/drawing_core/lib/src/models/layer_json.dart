part of 'layer.dart';

// JSON (de)serialization for [Layer]. The stored format is part of saved
// notebooks: keep keys and value encodings stable.
//
// Each element is decoded on its own. An element that fails to decode is kept
// as an [UnreadableElement] and written back into its original list, so one
// bad or newer-version element never makes the whole notebook unopenable.

Map<String, dynamic> _layerToJson(Layer layer) {
  List<Object?> withUnreadable(String key, Iterable<Object?> decoded) => [
        ...decoded,
        for (final e in layer.unreadableElements)
          if (e.listKey == key) e.raw,
      ];

  return {
    'id': layer.id,
    'name': layer.name,
    'strokes': withUnreadable('strokes', layer.strokes.map((s) => s.toJson())),
    'shapes': withUnreadable('shapes', layer.shapes.map((s) => s.toJson())),
    'texts': withUnreadable('texts', layer.texts.map((t) => t.toJson())),
    'images': withUnreadable('images', layer.images.map((i) => i.toJson())),
    'stickyNotes':
        withUnreadable('stickyNotes', layer.stickyNotes.map((n) => n.toJson())),
    'elementOrder': layer.elementOrder,
    'isVisible': layer.isVisible,
    'isLocked': layer.isLocked,
    'opacity': layer.opacity,
  };
}

Layer _layerFromJson(Map<String, dynamic> json) {
  final unreadable = <UnreadableElement>[];
  final layerId = json['id'] as String;

  List<T> decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) decode,
  ) {
    final list = json[key] as List?;
    if (list == null) return const [];
    final result = <T>[];
    for (final raw in list) {
      try {
        result.add(decode(raw as Map<String, dynamic>));
      } catch (error, stackTrace) {
        unreadable.add(UnreadableElement(listKey: key, raw: raw));
        developer.log(
          'Kept unreadable $key element in layer $layerId: $error',
          name: 'drawing_core.layer',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return result;
  }

  return Layer(
    id: layerId,
    name: json['name'] as String,
    strokes: decodeList('strokes', Stroke.fromJson),
    shapes: decodeList('shapes', Shape.fromJson),
    texts: decodeList('texts', TextElement.fromJson),
    images: decodeList('images', ImageElement.fromJson),
    stickyNotes: decodeList('stickyNotes', StickyNote.fromJson),
    elementOrder:
        (json['elementOrder'] as List?)?.whereType<String>().toList() ??
            const [],
    unreadableElements: unreadable,
    isVisible: json['isVisible'] as bool? ?? true,
    isLocked: json['isLocked'] as bool? ?? false,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
  );
}
