import 'package:drawing_core/drawing_core.dart';

/// Size for a page added to [doc] next to the page at [currentIndex].
///
/// A notebook created with its own paper size stores it in
/// `settings.defaultPageSize`, which wins. Notebooks saved before that still
/// hold the A4-portrait fallback: they take the size of the current page, or
/// of the last page, when that is a template page (not a cover, PDF or image
/// page). Imported PDF notebooks have no template page and keep the default.
PageSize resolveNewPageSize(DrawingDocument doc, int currentIndex) {
  final configured = doc.settings.defaultPageSize;
  if (configured != DocumentSettings.defaults().defaultPageSize) {
    return configured;
  }
  final pages = doc.pages;
  if (currentIndex >= 0 &&
      currentIndex < pages.length &&
      _isTemplatePage(pages[currentIndex])) {
    return pages[currentIndex].size;
  }
  for (var i = pages.length - 1; i >= 0; i--) {
    if (_isTemplatePage(pages[i])) return pages[i].size;
  }
  return configured;
}

bool _isTemplatePage(Page page) =>
    !page.isCover &&
    page.background.type != BackgroundType.pdf &&
    page.background.type != BackgroundType.cover;
