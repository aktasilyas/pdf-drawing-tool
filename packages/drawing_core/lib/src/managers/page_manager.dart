import 'package:drawing_core/src/models/page.dart';
import 'package:drawing_core/src/models/page_background.dart';
import 'package:drawing_core/src/models/page_size.dart';

/// Manager class for page operations and navigation.
///
/// [PageManager] provides a mutable interface for managing pages in a document,
/// including navigation, CRUD operations, and reordering.
///
/// This is a stateful manager - operations directly modify the internal state.
/// For immutable document operations, use [DrawingDocument] instead.
class PageManager {
  final List<Page> _pages;
  int _currentIndex;

  /// Creates a [PageManager] with optional pages and current index.
  ///
  /// If [pages] is null or empty, creates a default page.
  /// If [currentIndex] is out of bounds, clamps to valid range.
  PageManager({List<Page>? pages, int currentIndex = 0})
      : _pages = (pages == null || pages.isEmpty)
            ? [Page.create(index: 0)]
            : List<Page>.from(pages),
        _currentIndex = 0 {
    // Clamp current index to valid range
    if (currentIndex < 0) {
      _currentIndex = 0;
    } else if (currentIndex >= _pages.length) {
      _currentIndex = _pages.length - 1;
    } else {
      _currentIndex = currentIndex;
    }
  }

  // ========== GETTERS ==========

  /// Returns an unmodifiable list of pages.
  List<Page> get pages => List.unmodifiable(_pages);

  /// The current page index.
  int get currentIndex => _currentIndex;

  /// The currently active page.
  Page get currentPage => _pages[_currentIndex];

  /// Total number of pages.
  int get pageCount => _pages.length;

  /// Whether navigation to next page is possible.
  bool get canGoNext => _currentIndex < _pages.length - 1;

  /// Whether navigation to previous page is possible.
  bool get canGoPrevious => _currentIndex > 0;

  // ========== NAVIGATION ==========

  /// Navigate to a specific page by index.
  ///
  /// Throws [RangeError] if [index] is out of bounds.
  void goToPage(int index) {
    if (index < 0 || index >= _pages.length) {
      throw RangeError.range(index, 0, _pages.length - 1, 'index');
    }
    _currentIndex = index;
  }

  /// Navigate to the next page.
  ///
  /// Does nothing if already at the last page.
  void nextPage() {
    if (canGoNext) {
      _currentIndex++;
    }
  }

  /// Navigate to the previous page.
  ///
  /// Does nothing if already at the first page.
  void previousPage() {
    if (canGoPrevious) {
      _currentIndex--;
    }
  }

  // ========== CRUD OPERATIONS ==========

  /// Add a new page at the end.
  ///
  /// Returns the newly created page.
  Page addPage({PageSize? size, PageBackground? background}) {
    final newIndex = _pages.length;
    final newPage = Page.create(
      index: newIndex,
      size: size,
      background: background,
    );
    _pages.add(newPage);
    return newPage;
  }

  /// Insert a new page at the specified index.
  ///
  /// All pages at or after [index] will have their indices updated.
  /// Returns the newly created page.
  Page insertPage(int index, {PageSize? size, PageBackground? background}) {
    if (index < 0 || index > _pages.length) {
      throw RangeError.range(index, 0, _pages.length, 'index');
    }

    final newPage = Page.create(
      index: index,
      size: size,
      background: background,
    );

    _pages.insert(index, newPage);
    _reindexPages();

    // Adjust current index if needed
    if (_currentIndex >= index) {
      _currentIndex++;
    }

    return newPage;
  }

  /// Delete a page at the specified index.
  ///
  /// Throws [StateError] if attempting to delete the last remaining page.
  /// Adjusts [currentIndex] if necessary.
  void deletePage(int index) {
    if (_pages.length <= 1) {
      throw StateError('Cannot delete the last page');
    }

    if (index < 0 || index >= _pages.length) {
      throw RangeError.range(index, 0, _pages.length - 1, 'index');
    }

    _pages.removeAt(index);
    _reindexPages();

    // Adjust current index
    if (_currentIndex > index) {
      // Deleted before current, shift left
      _currentIndex--;
    } else if (_currentIndex == index) {
      // Deleted current page
      if (_currentIndex >= _pages.length) {
        // Was on last page, move to new last
        _currentIndex = _pages.length - 1;
      }
      // Otherwise stay at same index (now showing next page)
    }
    // If deleted after current, no adjustment needed
  }

  /// Duplicate a page and insert it right after the original.
  ///
  /// Returns the newly created duplicate page.
  void duplicatePage(int index) {
    if (index < 0 || index >= _pages.length) {
      throw RangeError.range(index, 0, _pages.length - 1, 'index');
    }

    final original = _pages[index];
    
    // Create a copy with updated index (will be adjusted by _reindexPages)
    final duplicate = Page(
      id: 'page_${DateTime.now().microsecondsSinceEpoch}',
      index: index + 1,
      size: original.size,
      background: original.background,
      layers: original.layers, // Copy layers reference
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pages.insert(index + 1, duplicate);
    _reindexPages();

    // Adjust current index if needed
    if (_currentIndex > index) {
      _currentIndex++;
    }
  }

  /// Reorder a page from [oldIndex] to [newIndex].
  ///
  /// All affected pages will have their indices updated.
  /// Adjusts [currentIndex] if necessary.
  void reorderPage(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _pages.length) {
      throw RangeError.range(oldIndex, 0, _pages.length - 1, 'oldIndex');
    }

    if (newIndex < 0 || newIndex >= _pages.length) {
      throw RangeError.range(newIndex, 0, _pages.length - 1, 'newIndex');
    }

    if (oldIndex == newIndex) {
      return; // No-op
    }

    final page = _pages.removeAt(oldIndex);
    _pages.insert(newIndex, page);
    _reindexPages();

    // Adjust current index
    if (_currentIndex == oldIndex) {
      // Moving the current page
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      // Moved from before to after or at current, shift left
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      // Moved from after to before or at current, shift right
      _currentIndex++;
    }
  }

  // ========== UPDATE OPERATIONS ==========

  /// Update a page at the specified index.
  ///
  /// Throws [RangeError] if [index] is out of bounds.
  void updatePage(int index, Page page) {
    if (index < 0 || index >= _pages.length) {
      throw RangeError.range(index, 0, _pages.length - 1, 'index');
    }

    _pages[index] = page;
  }

  /// Update the currently active page.
  void updateCurrentPage(Page page) {
    _pages[_currentIndex] = page;
  }

  // ========== PRIVATE HELPERS ==========

  /// Re-index all pages to match their position in the list.
  void _reindexPages() {
    for (int i = 0; i < _pages.length; i++) {
      if (_pages[i].index != i) {
        _pages[i] = _pages[i].copyWith(index: i);
      }
    }
  }
}
