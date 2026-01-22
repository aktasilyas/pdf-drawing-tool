import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/background_thumbnail_queue.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';

void main() {
  group('ThumbnailTask', () {
    test('should create with required parameters', () {
      final page = Page.create(index: 0);
      final task = ThumbnailTask(
        page: page,
        priority: 1.0,
      );

      expect(task.page, page);
      expect(task.priority, 1.0);
      expect(task.width, 150);
      expect(task.height, 200);
    });

    test('should create with custom dimensions', () {
      final page = Page.create(index: 0);
      final task = ThumbnailTask(
        page: page,
        priority: 0.5,
        width: 100,
        height: 150,
      );

      expect(task.width, 100);
      expect(task.height, 150);
    });

    test('should have unique id', () {
      final page = Page.create(index: 0);
      final task1 = ThumbnailTask(page: page, priority: 1.0);
      final task2 = ThumbnailTask(page: page, priority: 1.0);

      expect(task1.id, isNot(equals(task2.id)));
    });

    test('should sort by priority descending', () {
      final page = Page.create(index: 0);
      final tasks = [
        ThumbnailTask(page: page, priority: 0.3),
        ThumbnailTask(page: page, priority: 0.8),
        ThumbnailTask(page: page, priority: 0.5),
      ];

      tasks.sort((a, b) => b.priority.compareTo(a.priority));

      expect(tasks[0].priority, 0.8);
      expect(tasks[1].priority, 0.5);
      expect(tasks[2].priority, 0.3);
    });
  });

  group('BackgroundThumbnailQueue', () {
    late ThumbnailCache cache;
    late BackgroundThumbnailQueue queue;

    setUp(() {
      cache = ThumbnailCache(maxSize: 10);
      queue = BackgroundThumbnailQueue(cache: cache);
    });

    tearDown(() {
      queue.dispose();
    });

    group('Constructor', () {
      test('should create with default settings', () {
        final q = BackgroundThumbnailQueue(cache: cache);
        
        expect(q.isProcessing, false);
        expect(q.queueLength, 0);
        
        q.dispose();
      });

      test('should create with custom concurrency', () {
        final q = BackgroundThumbnailQueue(
          cache: cache,
          maxConcurrent: 3,
        );
        
        expect(q.maxConcurrent, 3);
        
        q.dispose();
      });
    });

    group('Queue Management', () {
      test('should enqueue task', () {
        final page = Page.create(index: 0);
        final task = ThumbnailTask(page: page, priority: 1.0);

        queue.enqueue(task);

        expect(queue.queueLength, 1);
      });

      test('should enqueue multiple tasks', () {
        for (int i = 0; i < 5; i++) {
          final page = Page.create(index: i);
          queue.enqueue(ThumbnailTask(page: page, priority: 1.0));
        }

        expect(queue.queueLength, 5);
      });

      test('should not enqueue duplicate page', () {
        final page = Page.create(index: 0);
        final task1 = ThumbnailTask(page: page, priority: 1.0);
        final task2 = ThumbnailTask(page: page, priority: 0.8);

        queue.enqueue(task1);
        queue.enqueue(task2); // Same page

        expect(queue.queueLength, 1);
      });

      test('should clear queue', () {
        for (int i = 0; i < 5; i++) {
          final page = Page.create(index: i);
          queue.enqueue(ThumbnailTask(page: page, priority: 1.0));
        }

        expect(queue.queueLength, greaterThan(0));

        queue.clear();

        expect(queue.queueLength, 0);
      });

      test('should remove specific task', () {
        final page1 = Page.create(index: 0);
        final page2 = Page.create(index: 1);
        final page3 = Page.create(index: 2);

        queue.enqueue(ThumbnailTask(page: page1, priority: 1.0));
        queue.enqueue(ThumbnailTask(page: page2, priority: 1.0));
        queue.enqueue(ThumbnailTask(page: page3, priority: 1.0));

        expect(queue.queueLength, 3);

        queue.removePageFromQueue(page2.id);

        expect(queue.queueLength, 2);
      });
    });

    group('Processing Control', () {
      test('should start processing', () {
        queue.startProcessing();
        expect(queue.isProcessing, true);
      });

      test('should stop processing', () {
        queue.startProcessing();
        expect(queue.isProcessing, true);

        queue.stopProcessing();
        expect(queue.isProcessing, false);
      });
    });

    group('Callbacks', () {
      test('should allow setting onTaskComplete callback', () {
        queue.onTaskComplete = (task, data) {};
        expect(queue.onTaskComplete, isNotNull);
      });

      test('should allow setting onTaskError callback', () {
        queue.onTaskError = (task, error) {};
        expect(queue.onTaskError, isNotNull);
      });
    });

    group('Disposal', () {
      test('should stop processing on dispose', () {
        queue.startProcessing();
        expect(queue.isProcessing, true);

        queue.dispose();
        
        // Queue is disposed
        expect(queue.queueLength, 0);
      });

      test('should be safe to call dispose multiple times', () {
        expect(() {
          queue.dispose();
          queue.dispose();
        }, returnsNormally);
      });
    });
  });
}
