import 'package:drawing_core/src/models/document.dart';
import 'package:drawing_core/src/models/page.dart';

/// Page structure operations for multi-page [DrawingDocument]s.
///
/// Kept in an extension so `document.dart` does not grow further. Every
/// operation re-numbers [Page.index] and keeps `currentPageIndex` pointing at
/// the same page (tracked by id, not by position).
extension DocumentPageOps on DrawingDocument {
  /// Moves the page at [from] to position [to] (remove + insert semantics).
  ///
  /// Returns this document unchanged when [from] or [to] is out of range or
  /// both are equal.
  DrawingDocument movePage(int from, int to) {
    final length = pages.length;
    // The cover is pinned to page 1: it cannot move, nothing goes before it.
    final floor = _firstAllowedIndex;
    if (floor == 1 && from == 0) return this;
    final target = to < 0 ? to : to.clamp(floor, length);
    if (from == target ||
        from < 0 ||
        target < 0 ||
        from >= length ||
        target >= length) {
      return this;
    }
    final list = List<Page>.from(pages);
    list.insert(target, list.removeAt(from));
    return _withPages(list, pages[currentPageIndex].id);
  }

  /// Lowest index a page may take: 1 when the first page is a cover.
  int get _firstAllowedIndex => pages.isNotEmpty && pages.first.isCover ? 1 : 0;

  /// Inserts [page] at [index], clamped to `[0, pages.length]` (`[1, ..]`
  /// when the document starts with a cover).
  DrawingDocument insertPageAt(int index, Page page) {
    final at = index.clamp(_firstAllowedIndex, pages.length);
    final list = List<Page>.from(pages)..insert(at, page);
    final currentId = pages.isEmpty ? null : pages[currentPageIndex].id;
    return _withPages(list, currentId);
  }

  /// Replaces the page list with [list] (re-numbered) and selects the page
  /// with [currentPageId], or the first page when it is not in [list].
  DrawingDocument replacePages(List<Page> list, {String? currentPageId}) =>
      _withPages(list, currentPageId);

  DrawingDocument _withPages(List<Page> list, String? currentId) {
    final renumbered = [
      for (var i = 0; i < list.length; i++)
        list[i].index == i ? list[i] : list[i].copyWith(index: i),
    ];
    final current = currentId == null
        ? 0
        : renumbered
            .indexWhere((p) => p.id == currentId)
            .clamp(0, list.length - 1);
    // Keep the active layer only while the current page is unchanged.
    final sameCurrent = renumbered[current].id == pages[currentPageIndex].id;
    final layer =
        sameCurrent && activeLayerIndex < renumbered[current].layers.length
            ? activeLayerIndex
            : 0;
    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: renumbered,
      currentPageIndex: current,
      activeLayerIndex: layer,
      settings: settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }
}
