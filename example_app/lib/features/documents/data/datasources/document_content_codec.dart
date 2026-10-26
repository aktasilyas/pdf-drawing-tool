import 'dart:convert';
import 'dart:isolate';

/// JSON codec for document content rows.
///
/// Large payloads are encoded and decoded on a short-lived background
/// isolate (`Isolate.run`) so autosave and document load do not block UI
/// frames. Small payloads stay inline: spawning an isolate costs about a
/// millisecond, more than encoding a few pages.
class DocumentContentCodec {
  const DocumentContentCodec({
    this.encodeOffloadWeight = defaultEncodeOffloadWeight,
    this.decodeOffloadLength = defaultDecodeOffloadLength,
  });

  /// Never leaves the calling isolate (benchmark baseline).
  const DocumentContentCodec.inline()
      : encodeOffloadWeight = null,
        decodeOffloadLength = null;

  /// [contentWeight] from which [encode] runs on a background isolate.
  static const int defaultEncodeOffloadWeight = 5000;

  /// JSON length (characters) from which [decode] runs on a background
  /// isolate; roughly the size [defaultEncodeOffloadWeight] produces.
  static const int defaultDecodeOffloadLength = 128 * 1024;

  /// `null` = always inline.
  final int? encodeOffloadWeight;

  /// `null` = always inline.
  final int? decodeOffloadLength;

  Future<String> encode(Map<String, dynamic> content) async {
    final limit = encodeOffloadWeight;
    if (limit == null || contentWeight(content) < limit) {
      return jsonEncode(content);
    }
    return Isolate.run(
      () => jsonEncode(content),
      debugName: 'document-content-encode',
    );
  }

  Future<Map<String, dynamic>> decode(String data) async {
    final limit = decodeOffloadLength;
    if (limit == null || data.length < limit) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    // The result comes back via Isolate.exit, without a copy.
    return Isolate.run(
      () => jsonDecode(data) as Map<String, dynamic>,
      debugName: 'document-content-decode',
    );
  }

  /// Cheap size estimate: one per page and stroke plus every stroke point.
  /// Walks the map without allocating; unknown shapes count as zero.
  static int contentWeight(Map<String, dynamic> content) {
    var weight = _layersWeight(content['layers']);
    final pages = content['pages'];
    if (pages is List) {
      for (final page in pages) {
        weight++;
        if (page is Map) weight += _layersWeight(page['layers']);
      }
    }
    return weight;
  }

  static int _layersWeight(Object? layers) {
    if (layers is! List) return 0;
    var weight = 0;
    for (final layer in layers) {
      if (layer is! Map) continue;
      final strokes = layer['strokes'];
      if (strokes is! List) continue;
      for (final stroke in strokes) {
        weight++;
        if (stroke is! Map) continue;
        final points = stroke['points'];
        if (points is List) weight += points.length;
      }
    }
    return weight;
  }
}
