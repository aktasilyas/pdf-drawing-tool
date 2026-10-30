/// Canvas z-order of a layer's elements, shared by every renderer (canvas
/// scene, tile cache, vector PDF export) so they cannot drift apart.
///
/// Each map holds the *visible* elements of one kind by id, in list order.
/// - Ids in [elementOrder] come first, in that order (unknown ids skipped).
/// - Elements missing from a non-empty [elementOrder] follow, sorted by id
///   (ids are creation timestamps; older notebooks stored no z-order).
/// - With an empty [elementOrder]: strokes, then shapes (list order), then
///   images and texts sorted by id.
///
/// [entry] builds one result item; it is called once per painted element.
List<T> elementPaintOrder<T>({
  required List<String> elementOrder,
  required Map<String, Object> strokes,
  Map<String, Object> shapes = const {},
  Map<String, Object> images = const {},
  Map<String, Object> texts = const {},
  required T Function(String id, Object element) entry,
}) {
  final result = <T>[];
  if (elementOrder.isNotEmpty) {
    final listed = <String>{};
    for (final id in elementOrder) {
      if (!listed.add(id)) continue;
      final e = strokes[id] ?? shapes[id] ?? images[id] ?? texts[id];
      if (e != null) result.add(entry(id, e));
    }
    final rest = <MapEntry<String, Object>>[
      for (final m in [strokes, shapes, images, texts])
        for (final e in m.entries)
          if (!listed.contains(e.key)) e,
    ]..sort((a, b) => a.key.compareTo(b.key));
    for (final e in rest) {
      result.add(entry(e.key, e.value));
    }
  } else {
    for (final m in [strokes, shapes]) {
      for (final e in m.entries) {
        result.add(entry(e.key, e.value));
      }
    }
    final objects = <MapEntry<String, Object>>[
      for (final m in [images, texts]) ...m.entries,
    ]..sort((a, b) => a.key.compareTo(b.key));
    for (final e in objects) {
      result.add(entry(e.key, e.value));
    }
  }
  return result;
}
