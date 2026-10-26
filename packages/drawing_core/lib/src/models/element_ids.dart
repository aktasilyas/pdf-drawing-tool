/// Generates element ids (strokes, shapes, images, texts, notes).
///
/// Ids keep the historical format, the microsecond timestamp as a string, so
/// sorting by id still follows creation order. Two ids created in the same
/// microsecond (for example when pasting many elements in a loop) would
/// collide, so each id is at least one greater than the previous one.
abstract final class ElementIds {
  static int _last = 0;

  /// A new id, unique within this isolate and increasing.
  static String next() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _last = now > _last ? now : _last + 1;
    return _last.toString();
  }
}
