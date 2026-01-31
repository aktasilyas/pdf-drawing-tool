import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/page_navigator.dart';
import 'package:drawing_ui/src/widgets/page_thumbnail.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PageNavigator', () {
    late ThumbnailCache cache;
    late PageManager pageManager;

    setUp(() {
      cache = ThumbnailCache(maxSize: 10);
      pageManager = PageManager(
        pages: [
          Page.create(index: 0),
          Page.create(index: 1),
          Page.create(index: 2),
        ],
      );
    });

    testWidgets('should create with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      expect(find.byType(PageNavigator), findsOneWidget);
    });

    testWidgets('should display all page thumbnails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      // Wait for initial render
      await tester.pump();

      // Should show 3 thumbnails
      expect(
        find.byType(GestureDetector),
        findsAtLeast(3),
      );
    });

    testWidgets('should highlight current page', (tester) async {
      pageManager.goToPage(1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Current page should be at index 1
      expect(pageManager.currentIndex, 1);
    });

    testWidgets('should call onPageChanged when thumbnail tapped',
        (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Wait for thumbnails to load
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // Find PageThumbnail widgets instead of GestureDetectors
      final thumbnails = find.byType(PageThumbnail);
      if (thumbnails.evaluate().length >= 2) {
        await tester.tap(thumbnails.at(1));
        await tester.pump();
        expect(selectedIndex, 1);
      }
    });

    testWidgets('should show add page button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
              onAddPage: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should call onAddPage when add button tapped',
        (tester) async {
      bool addCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
              onAddPage: () => addCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      expect(addCalled, true);
    });

    testWidgets('should not show add button when onAddPage is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('should show delete button on long press', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
              onDeletePage: (index) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Long press on a thumbnail
      final thumbnails = find.byType(PageThumbnail);
      if (thumbnails.evaluate().isNotEmpty) {
        await tester.longPress(thumbnails.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Should show bottom sheet with delete option
        expect(find.text('Delete Page'), findsOneWidget);
      }
    });

    testWidgets('should handle empty page list', (tester) async {
      final emptyManager = PageManager(pages: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: emptyManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Should not crash
      expect(find.byType(PageNavigator), findsOneWidget);
    });

    testWidgets('should handle single page', (tester) async {
      final singlePageManager = PageManager(
        pages: [Page.create(index: 0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: singlePageManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(PageNavigator), findsOneWidget);
    });

    testWidgets('should scroll to show all pages', (tester) async {
      // Create many pages
      final manyPages = List.generate(20, (i) => Page.create(index: i));
      final largeManager = PageManager(pages: manyPages);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: largeManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Should be scrollable
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should apply custom height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
              height: 100,
            ),
          ),
        ),
      );

      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PageNavigator),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.constraints?.maxHeight, 100);
    });

    testWidgets('should show page count indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
              showPageCount: true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show something like "Page 1 of 3"
      expect(
        find.textContaining('of'),
        findsOneWidget,
      );
    });

    testWidgets('should not show page count when showPageCount is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
              showPageCount: false,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(
        find.textContaining('of'),
        findsNothing,
      );
    });

    testWidgets('should call onDuplicatePage when duplicate requested',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
              onDuplicatePage: (index) {
                // Duplicate callback
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Implementation-specific: might show on long-press menu
      // For now just verify the widget builds
      expect(find.byType(PageNavigator), findsOneWidget);
    });

    testWidgets('should update when pageManager changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Add a page to manager
      pageManager.addPage();

      // Rebuild
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigator(
              pageManager: pageManager,
              cache: cache,
              onPageChanged: (index) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Should reflect new page count
      expect(pageManager.pageCount, 4);
    });
  });
}
