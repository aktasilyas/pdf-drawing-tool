import 'package:drawing_core/drawing_core.dart';

/// Builds a multi-page document whose current page holds [layers].
///
/// `DrawingDocument.copyWith(layers: ...)` is ignored for multi-page
/// documents, so layers must be set on the [Page] itself.
DrawingDocument multiPageDocWithLayers(String title, List<Layer> layers) {
  final doc = DrawingDocument.emptyMultiPage(title);
  final page = doc.pages[doc.currentPageIndex].copyWith(layers: layers);
  return doc.copyWith(
    pages: [
      for (var i = 0; i < doc.pages.length; i++)
        i == doc.currentPageIndex ? page : doc.pages[i]
    ],
  );
}
