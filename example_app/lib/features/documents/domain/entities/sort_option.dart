/// Sort options for documents list
library;

/// Option to sort documents by
enum SortOption {
  /// Sort by date (updatedAt)
  date,

  /// Sort by name (title)
  name,

  /// Sort by size (pageCount)
  size,
}

/// Direction to sort
enum SortDirection {
  /// Ascending order (A→Z, old→new, small→large)
  ascending,

  /// Descending order (Z→A, new→old, large→small)
  descending,
}
