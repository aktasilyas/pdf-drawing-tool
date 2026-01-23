import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// Provider for PageManager state.
final pageManagerProvider =
    StateNotifierProvider<PageManagerNotifier, PageManager>((ref) {
  return PageManagerNotifier();
});

/// Notifier for PageManager state management.
class PageManagerNotifier extends StateNotifier<PageManager> {
  PageManagerNotifier() : super(PageManager());

  /// Adds a new page.
  Page addPage({
    PageSize? size,
    PageBackground? background,
  }) {
    final newPage = state.addPage(size: size, background: background);
    state = PageManager(
      pages: state.pages,
      currentIndex: state.currentIndex,
    );
    return newPage;
  }

  /// Inserts a page at specific index.
  Page insertPage(
    int index, {
    PageSize? size,
    PageBackground? background,
  }) {
    final newPage = state.insertPage(
      index,
      size: size,
      background: background,
    );
    state = PageManager(
      pages: state.pages,
      currentIndex: state.currentIndex,
    );
    return newPage;
  }

  /// Deletes a page at index.
  void deletePage(int index) {
    state.deletePage(index);
    state = PageManager(
      pages: state.pages,
      currentIndex: state.currentIndex,
    );
  }

  /// Duplicates a page.
  void duplicatePage(int index) {
    state.duplicatePage(index);
    state = PageManager(
      pages: state.pages,
      currentIndex: state.currentIndex,
    );
  }

  /// Reorders a page.
  void reorderPage(int oldIndex, int newIndex) {
    state.reorderPage(oldIndex, newIndex);
    state = PageManager(
      pages: state.pages,
      currentIndex: state.currentIndex,
    );
  }

  /// Navigates to a specific page.
  void goToPage(int index) {
    state.goToPage(index);
    state = PageManager(
      pages: state.pages,
      currentIndex: state.currentIndex,
    );
  }

  /// Navigates to next page.
  void nextPage() {
    if (state.canGoNext) {
      state.nextPage();
      state = PageManager(
        pages: state.pages,
        currentIndex: state.currentIndex,
      );
    }
  }

  /// Navigates to previous page.
  void previousPage() {
    if (state.canGoPrevious) {
      state.previousPage();
      state = PageManager(
        pages: state.pages,
        currentIndex: state.currentIndex,
      );
    }
  }

  /// Updates a specific page.
  void updatePage(int index, Page page) {
    state.updatePage(index, page);
    state = PageManager(
      pages: state.pages,
      currentIndex: state.currentIndex,
    );
  }

  /// Updates the current page.
  void updateCurrentPage(Page page) {
    state.updateCurrentPage(page);
    state = PageManager(
      pages: state.pages,
      currentIndex: state.currentIndex,
    );
  }

  /// Loads pages from a document.
  void loadFromDocument(DrawingDocument document) {
    state = PageManager(
      pages: document.pages,
      currentIndex: document.currentPageIndex,
    );
  }

  /// Exports to a DrawingDocument.
  DrawingDocument toDocument({
    required String id,
    required String title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: state.pages,
      currentPageIndex: state.currentIndex,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Disposes the notifier.
  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}

/// Provider for current page.
final currentPageProvider = Provider<Page>((ref) {
  final manager = ref.watch(pageManagerProvider);
  return manager.currentPage;
});

/// Provider for current page index.
final currentPageIndexProvider = Provider<int>((ref) {
  final manager = ref.watch(pageManagerProvider);
  return manager.currentIndex;
});

/// Provider for page count.
final pageCountProvider = Provider<int>((ref) {
  final manager = ref.watch(pageManagerProvider);
  return manager.pageCount;
});

/// Provider for checking if can go to next page.
final canGoNextProvider = Provider<bool>((ref) {
  final manager = ref.watch(pageManagerProvider);
  return manager.canGoNext;
});

/// Provider for checking if can go to previous page.
final canGoPreviousProvider = Provider<bool>((ref) {
  final manager = ref.watch(pageManagerProvider);
  return manager.canGoPrevious;
});

/// Provider for all pages.
final pagesProvider = Provider<List<Page>>((ref) {
  final manager = ref.watch(pageManagerProvider);
  return manager.pages;
});
