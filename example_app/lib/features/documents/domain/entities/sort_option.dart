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

extension SortOptionExtension on SortOption {
  /// Get display name for UI
  String get displayName {
    switch (this) {
      case SortOption.date:
        return 'Tarih';
      case SortOption.name:
        return 'İsim';
      case SortOption.size:
        return 'Boyut';
    }
  }
}

extension SortDirectionExtension on SortDirection {
  /// Get icon for UI
  String get icon {
    switch (this) {
      case SortDirection.ascending:
        return '↑';
      case SortDirection.descending:
        return '↓';
    }
  }
  
  /// Get description for UI
  String getDescription(SortOption option) {
    switch (option) {
      case SortOption.date:
        return this == SortDirection.descending ? 'Yeni → Eski' : 'Eski → Yeni';
      case SortOption.name:
        return this == SortDirection.descending ? 'Z → A' : 'A → Z';
      case SortOption.size:
        return this == SortDirection.descending ? 'Büyük → Küçük' : 'Küçük → Büyük';
    }
  }
}
