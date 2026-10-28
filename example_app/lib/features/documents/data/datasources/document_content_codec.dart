import 'dart:convert';
import 'dart:isolate';

import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/documents/domain/entities/encoded_json.dart';

/// JSON codec for document content rows, built so large notebooks do not
/// block UI frames. Small payloads are handled in one go.
///
/// - [decode] of a large payload runs on a short-lived background isolate
///   (`Isolate.run`): the string goes in cheaply and the decoded map comes
///   back via `Isolate.exit` without a copy.
/// - [encode] of a large payload runs on the calling isolate in time slices
///   (page by page, yielding to the event loop every [sliceBudget]).
///   `Isolate.run` would have to copy the whole map graph synchronously on
///   the calling isolate first, which the benchmark measured as slower than
///   encoding it (`test/benchmark/document_content_benchmark_test.dart`).
class DocumentContentCodec {
  const DocumentContentCodec({
    this.encodeSliceWeight = defaultEncodeSliceWeight,
    this.decodeOffloadLength = defaultDecodeOffloadLength,
    this.sliceBudget = defaultSliceBudget,
  });

  /// Single-shot encode and decode on the calling isolate (benchmark
  /// baseline).
  const DocumentContentCodec.inline()
      : encodeSliceWeight = null,
        decodeOffloadLength = null,
        sliceBudget = defaultSliceBudget;

  /// [contentWeight] from which [encode] works in time slices.
  static const int defaultEncodeSliceWeight = 5000;

  /// JSON length (characters) from which [decode] runs on a background
  /// isolate; roughly the size [defaultEncodeSliceWeight] produces.
  static const int defaultDecodeOffloadLength = 128 * 1024;

  /// Longest stretch [encode] works before yielding to the event loop.
  static const Duration defaultSliceBudget = Duration(milliseconds: 4);

  /// `null` = always single-shot.
  final int? encodeSliceWeight;

  /// `null` = always inline.
  final int? decodeOffloadLength;

  final Duration sliceBudget;

  /// Same output as `jsonEncode(content)`.
  Future<String> encode(Map<String, dynamic> content) async {
    final limit = encodeSliceWeight;
    if (limit == null ||
        (!_hasEncodedPages(content) && contentWeight(content) < limit)) {
      return jsonEncode(content);
    }
    return _encodeInSlices(content);
  }

  static bool _hasEncodedPages(Map<String, dynamic> content) {
    final pages = content['pages'];
    return pages is List && pages.any((p) => p is EncodedJson);
  }

  Future<String> _encodeInSlices(Map<String, dynamic> content) async {
    final pages = content['pages'];
    if (pages is! List) return jsonEncode(content);
    final out = StringBuffer('{');
    final slice = Stopwatch()..start();
    var firstEntry = true;
    for (final entry in content.entries) {
      if (!firstEntry) out.write(',');
      firstEntry = false;
      out.write('${jsonEncode(entry.key)}:');
      if (!identical(entry.value, pages)) {
        out.write(jsonEncode(entry.value));
        continue;
      }
      out.write('[');
      for (var i = 0; i < pages.length; i++) {
        if (i > 0) out.write(',');
        final page = pages[i];
        out.write(page is EncodedJson ? page.text : jsonEncode(page));
        if (slice.elapsed >= sliceBudget) {
          // A timer, not a microtask, so frames can run in between.
          await Future<void>.delayed(Duration.zero);
          slice.reset();
        }
      }
      out.write(']');
    }
    out.write('}');
    return out.toString();
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

  /// Decodes [data] into a document. A large payload is decoded and turned
  /// into a [DrawingDocument] on one background isolate, and the finished
  /// model comes back via `Isolate.exit` without a copy.
  Future<DrawingDocument> decodeDocument(String data) async {
    final limit = decodeOffloadLength;
    if (limit == null || data.length < limit) {
      return DrawingDocument.fromJson(
        jsonDecode(data) as Map<String, dynamic>,
      );
    }
    return Isolate.run(
      () => DrawingDocument.fromJson(jsonDecode(data) as Map<String, dynamic>),
      debugName: 'document-model-decode',
    );
  }

  /// Background JSON of the first page of V2 content, or null when the
  /// content has no pages (V1, empty or unexpected shapes). Skips building
  /// the page and stroke models; a large payload is decoded on a background
  /// isolate and only the background map comes back. Throws on invalid JSON.
  Future<Map<String, dynamic>?> decodeFirstPageBackground(String data) async {
    final limit = decodeOffloadLength;
    if (limit == null || data.length < limit) {
      return _firstPageBackground(jsonDecode(data));
    }
    return Isolate.run(
      () => _firstPageBackground(jsonDecode(data)),
      debugName: 'document-first-background-decode',
    );
  }

  static Map<String, dynamic>? _firstPageBackground(Object? json) {
    if (json is! Map) return null;
    final version = switch (json['version']) {
      final num v => v.toInt(),
      final String v => int.tryParse(v),
      _ => null,
    };
    if (version == null || version < 2) return null;
    final pages = json['pages'];
    if (pages is! List || pages.isEmpty) return null;
    final first = pages.first;
    if (first is! Map) return null;
    final background = first['background'];
    return background is Map<String, dynamic> ? background : null;
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
