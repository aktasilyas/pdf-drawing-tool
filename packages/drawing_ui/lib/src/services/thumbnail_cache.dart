import 'dart:typed_data';

/// LRU (Least Recently Used) cache for page thumbnails.
///
/// Stores thumbnail image data in memory with a maximum capacity.
/// When the cache is full, the least recently accessed item is evicted.
class ThumbnailCache {
  /// Maximum number of thumbnails to cache.
  final int maxSize;

  /// Internal cache storage.
  final Map<String, Uint8List> _cache = {};

  /// Access order tracking for LRU eviction.
  /// Most recently accessed items are at the end.
  final List<String> _accessOrder = [];

  /// Creates a [ThumbnailCache] with the specified maximum size.
  ///
  /// [maxSize] defaults to 20 thumbnails.
  ThumbnailCache({this.maxSize = 20});

  /// Current number of cached thumbnails.
  int get size => _cache.length;

  /// Retrieves a thumbnail from the cache.
  ///
  /// Returns null if the key is not found.
  /// Updates the access order when a thumbnail is retrieved.
  Uint8List? get(String key) {
    final data = _cache[key];
    if (data != null) {
      _updateAccessOrder(key);
    }
    return data;
  }

  /// Stores a thumbnail in the cache.
  ///
  /// If the key already exists, updates the data and access order.
  /// If the cache is full, evicts the least recently used item first.
  void put(String key, Uint8List data) {
    if (_cache.containsKey(key)) {
      // Update existing entry
      _cache[key] = data;
      _updateAccessOrder(key);
    } else {
      // Add new entry
      _evictIfNeeded();
      _cache[key] = data;
      _accessOrder.add(key);
    }
  }

  /// Removes a thumbnail from the cache.
  ///
  /// Does nothing if the key doesn't exist.
  void remove(String key) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// Checks if a key exists in the cache.
  bool contains(String key) {
    return _cache.containsKey(key);
  }

  /// Clears all cached thumbnails.
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Updates the access order for a key (moves to most recent).
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Evicts the least recently used item if cache is at capacity.
  void _evictIfNeeded() {
    if (_cache.length >= maxSize) {
      // Remove the least recently used (first in access order)
      final lruKey = _accessOrder.removeAt(0);
      _cache.remove(lruKey);
    }
  }
}
