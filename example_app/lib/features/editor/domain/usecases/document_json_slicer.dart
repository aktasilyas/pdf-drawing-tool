import 'package:drawing_core/drawing_core.dart';

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

  Future<Map<String, dynamic>> toJson(DrawingDocument document) async {
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
