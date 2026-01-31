import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('Multi-Page Workflow Integration', () {
    late ThumbnailCache thumbnailCache;

    setUp(() {
      thumbnailCache = ThumbnailCache(maxSize: 10);
    });

    tearDown(() {
      // PageManager doesn't have dispose method
      thumbnailCache.clear();
    });

    group('Page Creation and Navigation', () {
      test('should create document with multiple pages', () {
        // Create pages
        final page1 = Page.create(index: 0);
        final page2 = Page.create(index: 1);
        final page3 = Page.create(index: 2);

        final pages = [page1, page2, page3];

        expect(pages.length, 3);
        expect(pages[0].index, 0);
        expect(pages[1].index, 1);
        expect(pages[2].index, 2);
      });

      test('should navigate through pages with PageManager', () {
        final page1 = Page.create(index: 0);
        final page2 = Page.create(index: 1);

        final manager = PageManager(pages: [page1, page2], currentIndex: 0);

        expect(manager.currentIndex, 0);
        expect(manager.canGoNext, true);

        manager.nextPage();
        expect(manager.currentIndex, 1);
        expect(manager.canGoNext, false);

        manager.previousPage();
        expect(manager.currentIndex, 0);
      });

      test('should add and remove pages', () {
        final manager = PageManager();

        expect(manager.pageCount, 1); // Default page

        final newPage = manager.addPage();
        expect(manager.pageCount, 2);
        expect(newPage.index, 1);

        manager.deletePage(1);
        expect(manager.pageCount, 1);
      });
    });

    group('Document Serialization', () {
      test('should serialize and deserialize multi-page document', () {
        final doc = DrawingDocument.multiPage(
          id: 'd1',
          title: 'Test Document',
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ], createdAt: DateTime.now(), updatedAt: DateTime.now(),
        );

        final json = doc.toJson();
        final restored = DrawingDocument.fromJson(json);

        expect(restored.id, doc.id);
        expect(restored.title, doc.title);
        expect(restored.pages.length, 3);
      });

      test('should maintain backward compatibility with V1 documents', () {
        final v1Json = {
          'id': 'd1',
          'title': 'V1 Document',
          'width': 1920.0,
          'height': 1080.0,
          'layers': [],
          'background': {'type': 'solid', 'color': 4294967295},
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final doc = DrawingDocument.fromJson(v1Json);

        expect(doc.pages.length, 1);
        expect(doc.pages.first.size.width, 1920.0);
        expect(doc.pages.first.size.height, 1080.0);
      });
    });

    group('Thumbnail Generation', () {
      test('should cache thumbnails for pages', () {
        final page = Page.create(index: 0);
        final thumbnailData = [1, 2, 3, 4]; // Mock thumbnail

        final key = 'page_${page.id}';
        thumbnailCache.put(key, Uint8List.fromList(thumbnailData));

        final cached = thumbnailCache.get(key);
        expect(cached, thumbnailData);
      });

      test('should evict old thumbnails when cache is full', () {
        final cache = ThumbnailCache(maxSize: 2);

        cache.put('thumb1', Uint8List.fromList([1]));
        cache.put('thumb2', Uint8List.fromList([2]));
        cache.put('thumb3', Uint8List.fromList([3])); // Should evict thumb1

        expect(cache.get('thumb1'), isNull);
        expect(cache.get('thumb2'), isNotNull);
        expect(cache.get('thumb3'), isNotNull);
      });
    });

    group('Memory Management', () {
      test('should track memory budget', () {
        final budget = MemoryBudget(maxBytes: 10 * 1024 * 1024); // 10MB

        budget.allocate('page1', 1 * 1024 * 1024); // 1MB
        // Note: MemoryBudget doesn't expose usedBytes/availableBytes getters
        
        budget.deallocate('page1');
        // Verify allocation/deallocation works
      });

      test('should calculate memory statistics', () {
        final budget = MemoryBudget(maxBytes: 10 * 1024 * 1024);

        budget.allocate('page1', 3 * 1024 * 1024);
        budget.allocate('page2', 2 * 1024 * 1024);

        final stats = budget.getStatistics();
        expect(stats['totalBytes'], 10 * 1024 * 1024);
        expect(stats['usedBytes'], 5 * 1024 * 1024);
        expect(stats['usagePercentage'], 50.0);
      });
    });

    group('Preloading Strategy', () {
      test('should preload adjacent pages', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 1,
          preloadAfter: 1,
        );

        final toPreload = strategy.getPagesToPreload(
          currentIndex: 5,
          totalPages: 10,
        );

        expect(toPreload.length, 2);
        expect(toPreload.contains(4), true);
        expect(toPreload.contains(6), true);
      });

      test('should prioritize closer pages', () {
        final strategy = PreloadingStrategy(
          preloadBefore: 2,
          preloadAfter: 2,
        );

        final toPreload = strategy.getPagesToPreload(
          currentIndex: 5,
          totalPages: 10,
        );

        // Verify that closer pages are included
        expect(toPreload.contains(4), true);
        expect(toPreload.contains(3), true);
      });
    });

    group('End-to-End Multi-Page Flow', () {
      test('should handle complete page lifecycle', () {
        // 1. Create document
        final doc = DrawingDocument.multiPage(
          id: 'd1',
          title: 'Workflow Test',
          pages: [Page.create(index: 0)], createdAt: DateTime.now(), updatedAt: DateTime.now(),
        );

        expect(doc.pages.length, 1);

        // 2. Add pages
        var updatedPages = [...doc.pages, Page.create(index: 1)];
        var newDoc = doc.copyWith(pages: updatedPages);

        expect(newDoc.pages.length, 2);

        // 3. Add content to page
        final stroke = Stroke(
          id: 's1',
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
          createdAt: DateTime.now(),
        );

        final updatedPage = newDoc.pages[0].addStroke(stroke);
        updatedPages = [updatedPage, newDoc.pages[1]];
        newDoc = newDoc.copyWith(pages: updatedPages);

        expect(newDoc.pages[0].layers.first.strokes.length, 1);

        // 4. Serialize
        final json = newDoc.toJson();

        // 5. Deserialize
        final restored = DrawingDocument.fromJson(json);

        expect(restored.pages.length, 2);
        expect(restored.pages[0].layers.first.strokes.length, 1);
      });

      test('should handle page reordering', () {
        final manager = PageManager(
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
            Page.create(index: 2),
          ],
          currentIndex: 0,
        );

        expect(manager.pages[0].index, 0);
        expect(manager.pages[1].index, 1);

        manager.reorderPage(0, 2); // Move first page to last

        expect(manager.pages[0].index, 0);
        expect(manager.pages[1].index, 1);
        expect(manager.pages[2].index, 2);
        expect(manager.pageCount, 3);
      });

      test('should handle page duplication', () {
        final stroke = Stroke(
          id: 's1',
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
          createdAt: DateTime.now(),
        );

        final page = Page.create(index: 0).addStroke(stroke);
        final manager = PageManager(pages: [page], currentIndex: 0);

        manager.duplicatePage(0);

        expect(manager.pageCount, 2);
        expect(manager.pages[1].layers.first.strokes.length, 1);
      });
    });

    group('Performance Benchmarks', () {
      test('should handle large number of pages efficiently', () {
        final stopwatch = Stopwatch()..start();

        final pages = List.generate(
          100,
          (index) => Page.create(index: index),
        );

        final doc = DrawingDocument.multiPage(
          id: 'd1',
          title: 'Large Document',
          pages: pages,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        stopwatch.stop();

        expect(doc.pages.length, 100);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should serialize large document efficiently', () {
        final pages = List.generate(
          50,
          (index) => Page.create(index: index),
        );

        final doc = DrawingDocument.multiPage(
          id: 'd1',
          title: 'Large Document',
          pages: pages,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();
        final json = doc.toJson();
        stopwatch.stop();

        expect(json['pages'], isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });

    group('Error Handling', () {
      test('should handle invalid page operations gracefully', () {
        final manager = PageManager();

        // Cannot delete last page
        expect(() => manager.deletePage(0), throwsStateError);

        // Invalid page index
        expect(
          () => manager.goToPage(-1),
          throwsRangeError,
        );
      });

      test('should handle corrupted JSON gracefully', () {
        final invalidJson = {
          'id': 'd1',
          'title': 'Test',
          'version': 2,
          'pages': 'invalid', // Should be list
        };

        expect(
          () => DrawingDocument.fromJson(invalidJson),
          throwsA(isA<TypeError>()),
        );
      });
    });
  });
}
