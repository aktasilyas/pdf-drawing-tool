import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/editor/domain/usecases/page_json_cache.dart';

/// Builds `document.toJson()` without one long UI-isolate stall.
///
/// A large multi-page document is converted page by page on the calling
/// isolate, yielding to the event loop every [sliceBudget]. Copying the
/// document into an isolate would cost more than converting it (see
/// `test/benchmark/document_content_benchmark_test.dart`). The result is
/// the same map `toJson()` returns, so the stored format is unchanged.
class DocumentJsonSlicer {
  const DocumentJsonSlicer({
    this.sliceWeight = defaultSliceWeight,
    this.sliceBudget = const Duration(milliseconds: 4),
  });

  /// Weight (see [weightOf]) from which conversion works in slices; matches
  /// `DocumentContentCodec.defaultEncodeSliceWeight`.
  static const int defaultSliceWeight = 5000;

  final int sliceWeight;
  final Duration sliceBudget;

  /// With a [cache], multi-page documents always go page by page and the
  /// `pages` entry holds already-encoded `EncodedJson` text per page
  /// (unchanged pages are not converted or encoded again). Without one the
  /// result is the plain map `toJson()` returns.
  Future<Map<String, dynamic>> toJson(
    DrawingDocument document, {
    PageJsonCache? cache,
  }) async {
    if (cache != null && document.isMultiPage && document.pages.isNotEmpty) {
      return _toCachedJson(document, cache);
    }
    if (!document.isMultiPage || weightOf(document) < sliceWeight) {
      return document.toJson();
    }
    final pages = document.pages;
    // Keeps toJson()'s key order; only the pages entry is rebuilt.
    final json = document.copyWith(pages: [pages.first]).toJson();
    final pageJson = <Map<String, dynamic>>[];
    final slice = Stopwatch()..start();
    for (final page in pages) {
      pageJson.add(page.toJson());
      if (slice.elapsed >= sliceBudget) {
        // A timer, not a microtask, so frames can run in between.
        await Future<void>.delayed(Duration.zero);
        slice.reset();
      }
    }
    json['pages'] = pageJson;
    return json;
  }

  Future<Map<String, dynamic>> _toCachedJson(
    DrawingDocument document,
    PageJsonCache cache,
  ) async {
    final pages = document.pages;
    // Keeps toJson()'s key order without converting a real page.
    final json = document
        .copyWith(pages: [pages.first.copyWith(layers: const [])]).toJson();
    final encoded = <Object>[];
    final slice = Stopwatch()..start();
    for (final page in pages) {
      encoded.add(cache.encode(page));
      if (slice.elapsed >= sliceBudget) {
        // A timer, not a microtask, so frames can run in between.
        await Future<void>.delayed(Duration.zero);
        slice.reset();
      }
    }
    json['pages'] = encoded;
    return json;
  }

  /// One per page and stroke plus every stroke point.
  static int weightOf(DrawingDocument document) {
    var weight = 0;
    for (final page in document.pages) {
      weight++;
      for (final layer in page.layers) {
        for (final stroke in layer.strokes) {
          weight += 1 + stroke.points.length;
        }
      }
    }
    return weight;
  }
}
