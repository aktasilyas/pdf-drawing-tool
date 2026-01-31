import 'dart:typed_data';

/// Manages memory budget for caching operations.
///
/// Tracks memory allocations and provides utilities for monitoring
/// and managing memory usage within a defined budget.
class MemoryBudget {
  /// Default maximum memory budget: 50 MB
  static const int defaultMaxBytes = 50 * 1024 * 1024;

  /// Maximum allowed memory in bytes.
  final int maxBytes;

  /// Internal map tracking allocations by key.
  final Map<String, int> _allocations = {};

  /// Creates a memory budget with the specified maximum bytes.
  ///
  /// Throws [ArgumentError] if [maxBytes] is not positive.
  MemoryBudget({this.maxBytes = defaultMaxBytes}) {
    if (maxBytes <= 0) {
      throw ArgumentError('maxBytes must be positive');
    }
  }

  /// Current total allocated bytes.
  int get currentBytes {
    return _allocations.values.fold(0, (sum, bytes) => sum + bytes);
  }

  /// Remaining bytes before reaching budget limit.
  int get remainingBytes {
    final remaining = maxBytes - currentBytes;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether current allocation exceeds the budget.
  bool get isOverBudget => currentBytes > maxBytes;

  /// Current memory usage as a percentage (0-100+).
  double get usagePercentage {
    if (maxBytes == 0) return 0.0;
    return currentBytes / maxBytes * 100.0;
  }

  /// Allocates memory for the given key.
  ///
  /// If the key already exists, updates the allocation size.
  void allocate(String key, int bytes) {
    _allocations[key] = bytes;
  }

  /// Allocates memory for a Uint8List.
  void allocateData(String key, Uint8List data) {
    allocate(key, data.length);
  }

  /// Deallocates memory for the given key.
  ///
  /// Does nothing if the key doesn't exist.
  void deallocate(String key) {
    _allocations.remove(key);
  }

  /// Gets the allocation size for a specific key.
  ///
  /// Returns 0 if the key doesn't exist.
  int getAllocationSize(String key) {
    return _allocations[key] ?? 0;
  }

  /// Gets a copy of all current allocations.
  Map<String, int> getAllocations() {
    return Map.unmodifiable(_allocations);
  }

  /// Clears all allocations.
  void clear() {
    _allocations.clear();
  }

  /// Checks if allocating additional bytes would exceed budget.
  bool wouldExceedBudget(int additionalBytes) {
    return currentBytes + additionalBytes > maxBytes;
  }

  /// Suggests how many items to evict to get back under budget.
  ///
  /// Uses [averageItemSize] to estimate eviction count.
  /// Returns 0 if not over budget.
  int suggestEvictionCount({required int averageItemSize}) {
    if (!isOverBudget || averageItemSize <= 0) return 0;

    final overageBytes = currentBytes - maxBytes;
    return (overageBytes / averageItemSize).ceil();
  }

  /// Gets memory statistics as a map.
  Map<String, dynamic> getStatistics() {
    return {
      'maxBytes': maxBytes,
      'currentBytes': currentBytes,
      'remainingBytes': remainingBytes,
      'usagePercentage': usagePercentage,
      'allocationCount': _allocations.length,
      'isOverBudget': isOverBudget,
    };
  }

  /// Formats bytes to human-readable string (B, KB, MB).
  static String formatBytes(num bytes) {
    if (bytes < 1024) {
      return '${bytes.toInt()} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'MemoryBudget('
        'current: ${formatBytes(currentBytes)}, '
        'max: ${formatBytes(maxBytes)}, '
        'usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}
