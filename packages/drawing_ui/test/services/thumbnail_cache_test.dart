import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';

void main() {
  group('ThumbnailCache', () {
    group('Constructor', () {
      test('should create with default max size', () {
        final cache = ThumbnailCache();

        expect(cache.maxSize, 20);
        expect(cache.size, 0);
      });

      test('should create with custom max size', () {
        final cache = ThumbnailCache(maxSize: 50);

        expect(cache.maxSize, 50);
        expect(cache.size, 0);
      });
    });

    group('Basic Operations', () {
      test('should store and retrieve thumbnail', () {
        final cache = ThumbnailCache();
        final data = Uint8List.fromList([1, 2, 3, 4]);

        cache.put('key1', data);

        expect(cache.get('key1'), data);
        expect(cache.size, 1);
      });

      test('should return null for non-existent key', () {
        final cache = ThumbnailCache();

        expect(cache.get('nonexistent'), isNull);
      });

      test('should update existing key', () {
        final cache = ThumbnailCache();
        final data1 = Uint8List.fromList([1, 2, 3]);
        final data2 = Uint8List.fromList([4, 5, 6]);

        cache.put('key1', data1);
        cache.put('key1', data2);

        expect(cache.get('key1'), data2);
        expect(cache.size, 1);
      });

      test('should remove thumbnail', () {
        final cache = ThumbnailCache();
        final data = Uint8List.fromList([1, 2, 3]);

        cache.put('key1', data);
        cache.remove('key1');

        expect(cache.get('key1'), isNull);
        expect(cache.size, 0);
      });

      test('should handle remove on non-existent key', () {
        final cache = ThumbnailCache();

        cache.remove('nonexistent');

        expect(cache.size, 0);
      });

      test('should clear all thumbnails', () {
        final cache = ThumbnailCache();
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));
        cache.put('key3', Uint8List.fromList([3]));

        cache.clear();

        expect(cache.size, 0);
        expect(cache.get('key1'), isNull);
        expect(cache.get('key2'), isNull);
        expect(cache.get('key3'), isNull);
      });
    });

    group('LRU Eviction', () {
      test('should not evict when under capacity', () {
        final cache = ThumbnailCache(maxSize: 3);
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));
        cache.put('key3', Uint8List.fromList([3]));

        expect(cache.size, 3);
        expect(cache.get('key1'), isNotNull);
        expect(cache.get('key2'), isNotNull);
        expect(cache.get('key3'), isNotNull);
      });

      test('should evict least recently used when at capacity', () {
        final cache = ThumbnailCache(maxSize: 2);
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));
        cache.put('key3', Uint8List.fromList([3])); // Should evict key1

        expect(cache.size, 2);
        expect(cache.get('key1'), isNull);
        expect(cache.get('key2'), isNotNull);
        expect(cache.get('key3'), isNotNull);
      });

      test('should update access order on get', () {
        final cache = ThumbnailCache(maxSize: 2);
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));

        // Access key1 to make it most recently used
        cache.get('key1');

        // Add key3, should evict key2 (LRU)
        cache.put('key3', Uint8List.fromList([3]));

        expect(cache.size, 2);
        expect(cache.get('key1'), isNotNull);
        expect(cache.get('key2'), isNull);
        expect(cache.get('key3'), isNotNull);
      });

      test('should update access order on put (update existing)', () {
        final cache = ThumbnailCache(maxSize: 2);
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));

        // Update key1 to make it most recently used
        cache.put('key1', Uint8List.fromList([10]));

        // Add key3, should evict key2 (LRU)
        cache.put('key3', Uint8List.fromList([3]));

        expect(cache.size, 2);
        expect(cache.get('key1')![0], 10);
        expect(cache.get('key2'), isNull);
        expect(cache.get('key3'), isNotNull);
      });

      test('should evict oldest when multiple items at capacity', () {
        final cache = ThumbnailCache(maxSize: 3);
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));
        cache.put('key3', Uint8List.fromList([3]));
        cache.put('key4', Uint8List.fromList([4])); // Evict key1
        cache.put('key5', Uint8List.fromList([5])); // Evict key2

        expect(cache.size, 3);
        expect(cache.get('key1'), isNull);
        expect(cache.get('key2'), isNull);
        expect(cache.get('key3'), isNotNull);
        expect(cache.get('key4'), isNotNull);
        expect(cache.get('key5'), isNotNull);
      });
    });

    group('Contains', () {
      test('should return true for existing key', () {
        final cache = ThumbnailCache();
        cache.put('key1', Uint8List.fromList([1]));

        expect(cache.contains('key1'), true);
      });

      test('should return false for non-existent key', () {
        final cache = ThumbnailCache();

        expect(cache.contains('nonexistent'), false);
      });

      test('should return false after removal', () {
        final cache = ThumbnailCache();
        cache.put('key1', Uint8List.fromList([1]));
        cache.remove('key1');

        expect(cache.contains('key1'), false);
      });
    });

    group('Edge Cases', () {
      test('should handle maxSize of 1', () {
        final cache = ThumbnailCache(maxSize: 1);
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));

        expect(cache.size, 1);
        expect(cache.get('key1'), isNull);
        expect(cache.get('key2'), isNotNull);
      });

      test('should handle empty data', () {
        final cache = ThumbnailCache();
        final emptyData = Uint8List(0);

        cache.put('key1', emptyData);

        expect(cache.get('key1'), emptyData);
        expect(cache.get('key1')!.length, 0);
      });

      test('should handle large data', () {
        final cache = ThumbnailCache();
        final largeData = Uint8List(1024 * 1024); // 1MB

        cache.put('key1', largeData);

        expect(cache.get('key1'), largeData);
        expect(cache.get('key1')!.length, 1024 * 1024);
      });

      test('should handle special characters in keys', () {
        final cache = ThumbnailCache();
        final data = Uint8List.fromList([1, 2, 3]);

        cache.put('key-with-dashes', data);
        cache.put('key_with_underscores', data);
        cache.put('key.with.dots', data);
        cache.put('key/with/slashes', data);

        expect(cache.size, 4);
        expect(cache.get('key-with-dashes'), isNotNull);
        expect(cache.get('key_with_underscores'), isNotNull);
        expect(cache.get('key.with.dots'), isNotNull);
        expect(cache.get('key/with/slashes'), isNotNull);
      });
    });
  });
}
