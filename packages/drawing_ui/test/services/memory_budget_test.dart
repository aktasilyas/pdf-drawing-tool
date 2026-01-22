import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/services/memory_budget.dart';

void main() {
  group('MemoryBudget', () {
    group('Constructor', () {
      test('should create with default budget', () {
        final budget = MemoryBudget();
        
        expect(budget.maxBytes, MemoryBudget.defaultMaxBytes);
        expect(budget.currentBytes, 0);
        expect(budget.isOverBudget, false);
      });

      test('should create with custom budget', () {
        final budget = MemoryBudget(maxBytes: 1024 * 1024); // 1 MB
        
        expect(budget.maxBytes, 1024 * 1024);
        expect(budget.currentBytes, 0);
      });

      test('should throw on invalid budget', () {
        expect(
          () => MemoryBudget(maxBytes: 0),
          throwsArgumentError,
        );
        
        expect(
          () => MemoryBudget(maxBytes: -100),
          throwsArgumentError,
        );
      });
    });

    group('Memory Tracking', () {
      late MemoryBudget budget;

      setUp(() {
        budget = MemoryBudget(maxBytes: 1000);
      });

      test('should track allocated bytes', () {
        budget.allocate('key1', 100);
        expect(budget.currentBytes, 100);

        budget.allocate('key2', 200);
        expect(budget.currentBytes, 300);
      });

      test('should track deallocated bytes', () {
        budget.allocate('key1', 100);
        budget.allocate('key2', 200);
        expect(budget.currentBytes, 300);

        budget.deallocate('key1');
        expect(budget.currentBytes, 200);
      });

      test('should handle deallocation of non-existent key', () {
        budget.allocate('key1', 100);
        budget.deallocate('key2'); // doesn't exist
        
        expect(budget.currentBytes, 100); // unchanged
      });

      test('should update allocation for existing key', () {
        budget.allocate('key1', 100);
        expect(budget.currentBytes, 100);

        budget.allocate('key1', 200); // update
        expect(budget.currentBytes, 200);
      });

      test('should handle multiple allocations and deallocations', () {
        budget.allocate('key1', 100);
        budget.allocate('key2', 200);
        budget.allocate('key3', 150);
        expect(budget.currentBytes, 450);

        budget.deallocate('key2');
        expect(budget.currentBytes, 250);

        budget.allocate('key4', 100);
        expect(budget.currentBytes, 350);
      });
    });

    group('Budget Status', () {
      test('should detect over budget', () {
        final budget = MemoryBudget(maxBytes: 500);
        
        budget.allocate('key1', 300);
        expect(budget.isOverBudget, false);

        budget.allocate('key2', 300);
        expect(budget.isOverBudget, true);
      });

      test('should calculate remaining bytes', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        expect(budget.remainingBytes, 1000);

        budget.allocate('key1', 300);
        expect(budget.remainingBytes, 700);

        budget.allocate('key2', 500);
        expect(budget.remainingBytes, 200);
      });

      test('should calculate usage percentage', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        expect(budget.usagePercentage, 0.0);

        budget.allocate('key1', 250);
        expect(budget.usagePercentage, 25.0);

        budget.allocate('key2', 500);
        expect(budget.usagePercentage, 75.0);
      });

      test('should handle usage over 100%', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        budget.allocate('key1', 1200);
        expect(budget.usagePercentage, 120.0);
      });
    });

    group('Allocation Tracking', () {
      test('should track allocation size for key', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        budget.allocate('key1', 100);
        expect(budget.getAllocationSize('key1'), 100);
        
        budget.allocate('key2', 200);
        expect(budget.getAllocationSize('key2'), 200);
      });

      test('should return 0 for non-existent key', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        expect(budget.getAllocationSize('nonexistent'), 0);
      });

      test('should return all allocations', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        budget.allocate('key1', 100);
        budget.allocate('key2', 200);
        budget.allocate('key3', 150);

        final allocations = budget.getAllocations();
        expect(allocations.length, 3);
        expect(allocations['key1'], 100);
        expect(allocations['key2'], 200);
        expect(allocations['key3'], 150);
      });

      test('should return immutable allocations map', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        budget.allocate('key1', 100);
        final allocations1 = budget.getAllocations();
        final allocations2 = budget.getAllocations();

        expect(identical(allocations1, allocations2), false);
      });
    });

    group('Clear', () {
      test('should clear all allocations', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        budget.allocate('key1', 100);
        budget.allocate('key2', 200);
        budget.allocate('key3', 150);
        expect(budget.currentBytes, 450);

        budget.clear();
        expect(budget.currentBytes, 0);
        expect(budget.getAllocations().isEmpty, true);
      });

      test('should be safe to clear empty budget', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        expect(() => budget.clear(), returnsNormally);
        expect(budget.currentBytes, 0);
      });
    });

    group('Helper Methods', () {
      test('should track Uint8List allocation', () {
        final budget = MemoryBudget(maxBytes: 1000);
        final data = Uint8List(100);
        
        budget.allocateData('key1', data);
        expect(budget.currentBytes, 100);
      });

      test('should handle empty Uint8List', () {
        final budget = MemoryBudget(maxBytes: 1000);
        final data = Uint8List(0);
        
        budget.allocateData('key1', data);
        expect(budget.currentBytes, 0);
      });

      test('should calculate if allocation would exceed budget', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        budget.allocate('key1', 800);
        
        expect(budget.wouldExceedBudget(100), false);
        expect(budget.wouldExceedBudget(200), false);
        expect(budget.wouldExceedBudget(300), true);
      });

      test('should suggest eviction count', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        budget.allocate('key1', 200);
        budget.allocate('key2', 300);
        budget.allocate('key3', 400);
        // Total: 900, over budget by 0

        budget.allocate('key4', 300);
        // Total: 1200, over budget by 200

        // Should suggest evicting at least 1 item to free ~200 bytes
        final evictionCount = budget.suggestEvictionCount(averageItemSize: 250);
        expect(evictionCount, greaterThanOrEqualTo(1));
      });
    });

    group('Statistics', () {
      test('should provide memory statistics', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        budget.allocate('key1', 200);
        budget.allocate('key2', 300);
        budget.allocate('key3', 100);

        final stats = budget.getStatistics();
        
        expect(stats['maxBytes'], 1000);
        expect(stats['currentBytes'], 600);
        expect(stats['remainingBytes'], 400);
        expect(stats['usagePercentage'], 60.0);
        expect(stats['allocationCount'], 3);
        expect(stats['isOverBudget'], false);
      });

      test('should format bytes to human readable', () {
        expect(MemoryBudget.formatBytes(500), '500 B');
        expect(MemoryBudget.formatBytes(1024), '1.0 KB');
        expect(MemoryBudget.formatBytes(1536), '1.5 KB');
        expect(MemoryBudget.formatBytes(1024 * 1024), '1.0 MB');
        expect(MemoryBudget.formatBytes(1024 * 1024 * 1.5), '1.5 MB');
      });
    });

    group('Edge Cases', () {
      test('should handle maximum integer allocation', () {
        final budget = MemoryBudget(maxBytes: 1000000000);
        
        expect(
          () => budget.allocate('key1', 999999999),
          returnsNormally,
        );
      });

      test('should handle many small allocations', () {
        final budget = MemoryBudget(maxBytes: 10000);
        
        for (int i = 0; i < 100; i++) {
          budget.allocate('key$i', 50);
        }
        
        expect(budget.currentBytes, 5000);
        expect(budget.getAllocations().length, 100);
      });

      test('should handle rapid allocation and deallocation', () {
        final budget = MemoryBudget(maxBytes: 1000);
        
        for (int i = 0; i < 100; i++) {
          budget.allocate('key1', 100);
          budget.deallocate('key1');
        }
        
        expect(budget.currentBytes, 0);
      });
    });
  });
}
