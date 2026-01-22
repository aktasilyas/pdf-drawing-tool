import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/services/preloading_strategy.dart';

void main() {
  group('PreloadingStrategy', () {
    group('Constructor', () {
      test('should create with default settings', () {
        final strategy = PreloadingStrategy();

        expect(strategy.preloadBefore, 1);
        expect(strategy.preloadAfter, 2);
        expect(strategy.maxPreloadCount, 3);
      });

      test('should create with custom settings', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 2,
          preloadAfter: 3,
          maxPreloadCount: 5,
        );

        expect(strategy.preloadBefore, 2);
        expect(strategy.preloadAfter, 3);
        expect(strategy.maxPreloadCount, 5);
      });

      test('should throw on invalid settings', () {
        expect(
          () => PreloadingStrategy(preloadBefore: -1),
          throwsArgumentError,
        );

        expect(
          () => PreloadingStrategy(preloadAfter: -1),
          throwsArgumentError,
        );

        expect(
          () => PreloadingStrategy(maxPreloadCount: 0),
          throwsArgumentError,
        );
      });
    });

    group('Page Indices to Preload', () {
      test('should preload adjacent pages in middle of document', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 1,
          preloadAfter: 2,
        );

        final indices = strategy.getPagesToPreload(
          currentIndex: 5,
          totalPages: 10,
        );

        expect(indices, containsAll([4, 6, 7]));
        expect(indices.contains(5), false); // Current page not included
      });

      test('should handle preloading at start of document', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 2,
          preloadAfter: 2,
        );

        final indices = strategy.getPagesToPreload(
          currentIndex: 0,
          totalPages: 10,
        );

        expect(indices, containsAll([1, 2]));
        expect(indices.contains(-1), false); // No negative indices
        expect(indices.contains(0), false); // Current page not included
      });

      test('should handle preloading at end of document', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 2,
          preloadAfter: 2,
        );

        final indices = strategy.getPagesToPreload(
          currentIndex: 9,
          totalPages: 10,
        );

        expect(indices, containsAll([7, 8]));
        expect(indices.contains(10), false); // No out-of-bounds indices
        expect(indices.contains(9), false); // Current page not included
      });

      test('should respect maxPreloadCount limit', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 5,
          preloadAfter: 5,
          maxPreloadCount: 3,
        );

        final indices = strategy.getPagesToPreload(
          currentIndex: 10,
          totalPages: 20,
        );

        expect(indices.length, lessThanOrEqualTo(3));
      });

      test('should prioritize pages closer to current', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 3,
          preloadAfter: 3,
          maxPreloadCount: 3,
        );

        final indices = strategy.getPagesToPreload(
          currentIndex: 5,
          totalPages: 10,
        );

        // Should prefer adjacent pages (4, 6, 7 or 4, 6, 3 etc.)
        expect(indices.length, lessThanOrEqualTo(3));
        // At least one should be immediately adjacent
        expect(indices.contains(4) || indices.contains(6), true);
      });

      test('should handle single page document', () {
        final strategy = PreloadingStrategy();

        final indices = strategy.getPagesToPreload(
          currentIndex: 0,
          totalPages: 1,
        );

        expect(indices.isEmpty, true);
      });

      test('should handle two page document', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 1,
          preloadAfter: 1,
        );

        final indices1 = strategy.getPagesToPreload(
          currentIndex: 0,
          totalPages: 2,
        );
        expect(indices1, [1]);

        final indices2 = strategy.getPagesToPreload(
          currentIndex: 1,
          totalPages: 2,
        );
        expect(indices2, [0]);
      });

      test('should return empty list for invalid current index', () {
        final strategy = PreloadingStrategy();

        final indices1 = strategy.getPagesToPreload(
          currentIndex: -1,
          totalPages: 10,
        );
        expect(indices1.isEmpty, true);

        final indices2 = strategy.getPagesToPreload(
          currentIndex: 10,
          totalPages: 10,
        );
        expect(indices2.isEmpty, true);
      });

      test('should return empty list for zero total pages', () {
        final strategy = PreloadingStrategy();

        final indices = strategy.getPagesToPreload(
          currentIndex: 0,
          totalPages: 0,
        );
        expect(indices.isEmpty, true);
      });
    });

    group('Priority Calculation', () {
      test('should assign higher priority to closer pages', () {
        final strategy = PreloadingStrategy();

        final priority1 = strategy.calculatePriority(
          pageIndex: 5,
          currentIndex: 4,
        );

        final priority2 = strategy.calculatePriority(
          pageIndex: 10,
          currentIndex: 4,
        );

        expect(priority1, greaterThan(priority2));
      });

      test('should assign same priority to equidistant pages', () {
        final strategy = PreloadingStrategy();

        final priority1 = strategy.calculatePriority(
          pageIndex: 3,
          currentIndex: 5,
        );

        final priority2 = strategy.calculatePriority(
          pageIndex: 7,
          currentIndex: 5,
        );

        expect(priority1, equals(priority2));
      });

      test('should handle current page priority', () {
        final strategy = PreloadingStrategy();

        final priority = strategy.calculatePriority(
          pageIndex: 5,
          currentIndex: 5,
        );

        expect(priority, isNotNull);
        // Current page should have highest priority
        expect(priority, equals(1.0));
      });

      test('should decrease priority with distance', () {
        final strategy = PreloadingStrategy();

        final priorities = List.generate(
          5,
          (i) => strategy.calculatePriority(
            pageIndex: i,
            currentIndex: 0,
          ),
        );

        // Priority should decrease as distance increases
        for (int i = 0; i < priorities.length - 1; i++) {
          expect(priorities[i], greaterThanOrEqualTo(priorities[i + 1]));
        }
      });
    });

    group('Prioritized Preload List', () {
      test('should return pages sorted by priority', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 2,
          preloadAfter: 2,
        );

        final prioritized = strategy.getPrioritizedPreloadList(
          currentIndex: 5,
          totalPages: 10,
        );

        // Should have page indices and priorities
        expect(prioritized.isNotEmpty, true);

        // Check that priorities are in descending order
        for (int i = 0; i < prioritized.length - 1; i++) {
          expect(
            prioritized[i].priority,
            greaterThanOrEqualTo(prioritized[i + 1].priority),
          );
        }
      });

      test('should respect maxPreloadCount in prioritized list', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 5,
          preloadAfter: 5,
          maxPreloadCount: 3,
        );

        final prioritized = strategy.getPrioritizedPreloadList(
          currentIndex: 10,
          totalPages: 20,
        );

        expect(prioritized.length, lessThanOrEqualTo(3));
      });

      test('should include both before and after pages', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 2,
          preloadAfter: 2,
        );

        final prioritized = strategy.getPrioritizedPreloadList(
          currentIndex: 5,
          totalPages: 10,
        );

        final indices = prioritized.map((p) => p.pageIndex).toList();

        // Should have pages both before and after current
        expect(indices.any((i) => i < 5), true);
        expect(indices.any((i) => i > 5), true);
      });
    });

    group('Should Preload', () {
      test('should recommend preloading when within range', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 2,
          preloadAfter: 2,
        );

        expect(
          strategy.shouldPreload(
            pageIndex: 4,
            currentIndex: 5,
            totalPages: 10,
          ),
          true,
        );

        expect(
          strategy.shouldPreload(
            pageIndex: 6,
            currentIndex: 5,
            totalPages: 10,
          ),
          true,
        );
      });

      test('should not recommend preloading when out of range', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 1,
          preloadAfter: 1,
        );

        expect(
          strategy.shouldPreload(
            pageIndex: 2,
            currentIndex: 5,
            totalPages: 10,
          ),
          false,
        );

        expect(
          strategy.shouldPreload(
            pageIndex: 8,
            currentIndex: 5,
            totalPages: 10,
          ),
          false,
        );
      });

      test('should not recommend preloading current page', () {
        final strategy = PreloadingStrategy();

        expect(
          strategy.shouldPreload(
            pageIndex: 5,
            currentIndex: 5,
            totalPages: 10,
          ),
          false,
        );
      });

      test('should not recommend preloading invalid indices', () {
        final strategy = PreloadingStrategy();

        expect(
          strategy.shouldPreload(
            pageIndex: -1,
            currentIndex: 5,
            totalPages: 10,
          ),
          false,
        );

        expect(
          strategy.shouldPreload(
            pageIndex: 10,
            currentIndex: 5,
            totalPages: 10,
          ),
          false,
        );
      });
    });

    group('Edge Cases', () {
      test('should handle large preload ranges', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 100,
          preloadAfter: 100,
          maxPreloadCount: 50,
        );

        final indices = strategy.getPagesToPreload(
          currentIndex: 50,
          totalPages: 100,
        );

        expect(indices.length, lessThanOrEqualTo(50));
      });

      test('should handle asymmetric preload ranges', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 5,
          preloadAfter: 1,
        );

        final indices = strategy.getPagesToPreload(
          currentIndex: 10,
          totalPages: 20,
        );

        // Should have more pages before than after
        final beforeCount = indices.where((i) => i < 10).length;
        final afterCount = indices.where((i) => i > 10).length;

        expect(beforeCount, greaterThan(afterCount));
      });
    });
  });
}
