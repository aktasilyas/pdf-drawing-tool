import 'package:drawing_core/src/models/element_ids.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/page.dart';
import 'package:drawing_core/src/models/shape.dart';
import 'package:drawing_core/src/models/stroke.dart';

/// Copies a [Page] for duplicate/paste.
extension PageCopy on Page {
  /// A deep copy with a new page id, new layer ids and a new id for every
  /// element (strokes, shapes, texts, images, sticky notes and the strokes
  /// and shapes inside notes), so nothing is shared with this page.
  ///
  /// `elementOrder` follows the new ids; ids that point at no element are
  /// dropped. The copy is neither a cover nor bookmarked and has no
  /// thumbnail. Its [Page.index] is fixed when it is inserted.
  Page copyWithFreshIds() {
    final now = DateTime.now();
    return Page(
      id: 'page_${ElementIds.next()}',
      index: index,
      size: size,
      background: background,
      layers: [for (final layer in layers) _copyLayer(layer)],
      createdAt: now,
      updatedAt: now,
    );
  }
}

Layer _copyLayer(Layer layer) {
  final ids = <String, String>{};
  String fresh(String old) => ids[old] = ElementIds.next();

  Stroke stroke(Stroke s) => s.copyWith(id: fresh(s.id));
  Shape shape(Shape s) => s.copyWith(id: fresh(s.id));

  final strokes = [for (final s in layer.strokes) stroke(s)];
  final shapes = [for (final s in layer.shapes) shape(s)];
  final texts = [for (final t in layer.texts) t.copyWith(id: fresh(t.id))];
  final images = [for (final i in layer.images) i.copyWith(id: fresh(i.id))];
  final notes = [
    for (final n in layer.stickyNotes)
      n.copyWith(
        id: fresh(n.id),
        strokes: [
          for (final s in n.strokes) s.copyWith(id: ElementIds.next()),
        ],
        shapes: [
          for (final s in n.shapes) s.copyWith(id: ElementIds.next()),
        ],
      ),
  ];

  return layer.copyWith(
    id: 'layer_${ElementIds.next()}',
    strokes: strokes,
    shapes: shapes,
    texts: texts,
    images: images,
    stickyNotes: notes,
    elementOrder: [
      for (final id in layer.elementOrder)
        if (ids[id] != null) ids[id]!,
    ],
  );
}
