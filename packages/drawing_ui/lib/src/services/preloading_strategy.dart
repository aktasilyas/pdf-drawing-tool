/// Represents a page with its preload priority.
class PreloadItem {
  /// The page index.
  final int pageIndex;

  /// The priority value (higher = more important).
  final double priority;

  const PreloadItem({
    required this.pageIndex,
    required this.priority,
  });

  @override
  String toString() => 'PreloadItem(index: $pageIndex, priority: $priority)';
}

/// Strategy for preloading adjacent pages to improve navigation performance.
///
/// Determines which pages should be preloaded based on the current page
/// and configurable preload ranges.
class PreloadingStrategy {
  /// Number of pages to preload before the current page.
  final int preloadBefore;

  /// Number of pages to preload after the current page.
  final int preloadAfter;

  /// Maximum total number of pages to preload.
  final int maxPreloadCount;

  /// Creates a preloading strategy with the specified settings.
  ///
  /// Throws [ArgumentError] if any value is negative or maxPreloadCount is zero.
  PreloadingStrategy({
    this.preloadBefore = 1,
    this.preloadAfter = 2,
    this.maxPreloadCount = 3,
  }) {
    if (preloadBefore < 0) {
      throw ArgumentError('preloadBefore must be non-negative');
    }
    if (preloadAfter < 0) {
      throw ArgumentError('preloadAfter must be non-negative');
    }
    if (maxPreloadCount <= 0) {
      throw ArgumentError('maxPreloadCount must be positive');
    }
  }

  /// Gets the list of page indices that should be preloaded.
  ///
  /// Returns indices of pages adjacent to [currentIndex], excluding the
  /// current page itself. Results are limited by [maxPreloadCount].
  List<int> getPagesToPreload({
    required int currentIndex,
    required int totalPages,
  }) {
    if (currentIndex < 0 ||
        currentIndex >= totalPages ||
        totalPages <= 0) {
      return [];
    }

    final candidates = <PreloadItem>[];

    // Add pages before current
    for (int i = 1; i <= preloadBefore; i++) {
      final index = currentIndex - i;
      if (index >= 0) {
        candidates.add(PreloadItem(
          pageIndex: index,
          priority: calculatePriority(
            pageIndex: index,
            currentIndex: currentIndex,
          ),
        ));
      }
    }

    // Add pages after current
    for (int i = 1; i <= preloadAfter; i++) {
      final index = currentIndex + i;
      if (index < totalPages) {
        candidates.add(PreloadItem(
          pageIndex: index,
          priority: calculatePriority(
            pageIndex: index,
            currentIndex: currentIndex,
          ),
        ));
      }
    }

    // Sort by priority (highest first)
    candidates.sort((a, b) => b.priority.compareTo(a.priority));

    // Take only maxPreloadCount items
    final toPreload = candidates.take(maxPreloadCount).toList();

    return toPreload.map((item) => item.pageIndex).toList();
  }

  /// Calculates the priority for preloading a specific page.
  ///
  /// Priority is inversely proportional to distance from current page.
  /// Current page has priority 1.0, adjacent pages have high priority,
  /// distant pages have lower priority.
  double calculatePriority({
    required int pageIndex,
    required int currentIndex,
  }) {
    final distance = (pageIndex - currentIndex).abs();

    if (distance == 0) {
      return 1.0; // Current page has highest priority
    }

    // Priority decreases with distance
    // Priority = 1 / (distance + 1)
    // This gives: distance 1 = 0.5, distance 2 = 0.33, distance 3 = 0.25, etc.
    return 1.0 / (distance + 1);
  }

  /// Gets a prioritized list of pages to preload.
  ///
  /// Returns [PreloadItem] objects sorted by priority (highest first).
  List<PreloadItem> getPrioritizedPreloadList({
    required int currentIndex,
    required int totalPages,
  }) {
    final indices = getPagesToPreload(
      currentIndex: currentIndex,
      totalPages: totalPages,
    );

    return indices
        .map((index) => PreloadItem(
              pageIndex: index,
              priority: calculatePriority(
                pageIndex: index,
                currentIndex: currentIndex,
              ),
            ))
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Determines if a specific page should be preloaded.
  ///
  /// Returns true if [pageIndex] is within the preload range of [currentIndex]
  /// and is a valid page index.
  bool shouldPreload({
    required int pageIndex,
    required int currentIndex,
    required int totalPages,
  }) {
    // Invalid indices
    if (pageIndex < 0 || pageIndex >= totalPages) {
      return false;
    }

    // Don't preload current page
    if (pageIndex == currentIndex) {
      return false;
    }

    final distance = (pageIndex - currentIndex).abs();

    // Check if within preload range
    if (pageIndex < currentIndex) {
      return distance <= preloadBefore;
    } else {
      return distance <= preloadAfter;
    }
  }

  @override
  String toString() {
    return 'PreloadingStrategy('
        'before: $preloadBefore, '
        'after: $preloadAfter, '
        'max: $maxPreloadCount)';
  }
}
