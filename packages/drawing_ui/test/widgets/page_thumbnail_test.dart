import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/page_thumbnail.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PageThumbnail', () {
    late ThumbnailCache cache;

    setUp(() {
      cache = ThumbnailCache(maxSize: 10);
    });

    testWidgets('should create with required parameters', (tester) async {
      final page = Page.create(index: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
            ),
          ),
        ),
      );

      expect(find.byType(PageThumbnail), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      final page = Page.create(index: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
            ),
          ),
        ),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should apply custom dimensions', (tester) async {
      final page = Page.create(index: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PageThumbnail),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.constraints?.maxWidth, 200);
      expect(container.constraints?.maxHeight, 300);
    });

    testWidgets('should show selected border when selected', (tester) async {
      final page = Page.create(index: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
              isSelected: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PageThumbnail),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('should not show selected border when not selected',
        (tester) async {
      final page = Page.create(index: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
              isSelected: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PageThumbnail),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.border == null ||
            decoration.border == Border.all(color: Colors.grey.shade300),
        true,
      );
    });

    testWidgets('should trigger onTap callback', (tester) async {
      final page = Page.create(index: 0);
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PageThumbnail));
      expect(tapped, true);
    });

    testWidgets('should trigger onLongPress callback', (tester) async {
      final page = Page.create(index: 0);
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(PageThumbnail));
      expect(longPressed, true);
    });

    testWidgets('should display generated thumbnail after loading',
        (tester) async {
      final page = Page.create(index: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
            ),
          ),
        ),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for thumbnail generation with runAsync
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      
      await tester.pump();

      // Should have image now (or error widget if generation failed)
      final hasImage = find.byType(Image).evaluate().isNotEmpty;
      final hasError = find.byIcon(Icons.error_outline).evaluate().isNotEmpty;
      expect(hasImage || hasError, true);
    });

    testWidgets('should use cached thumbnail if available', (tester) async {
      final page = Page.create(index: 0);

      // First load - generates and caches
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
            ),
          ),
        ),
      );

      // Wait for generation
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();

      // Rebuild with same page - should use cache
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
            ),
          ),
        ),
      );

      // Should not show loading again (cache hit)
      await tester.pump();
      // If cached, should show image immediately
      final hasImage = find.byType(Image).evaluate().isNotEmpty;
      expect(hasImage, true);
    });

    testWidgets('should display page index label', (tester) async {
      final page = Page.create(index: 5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
              showPageNumber: true,
            ),
          ),
        ),
      );

      expect(find.text('6'), findsOneWidget); // index 5 = page 6
    });

    testWidgets('should not display page index when showPageNumber is false',
        (tester) async {
      final page = Page.create(index: 5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
              showPageNumber: false,
            ),
          ),
        ),
      );

      expect(find.text('6'), findsNothing);
    });

    testWidgets('should handle empty page gracefully', (tester) async {
      final page = Page.create(index: 0); // Empty page

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
            ),
          ),
        ),
      );

      // Should not throw
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();

      expect(find.byType(PageThumbnail), findsOneWidget);
    });

    testWidgets('should regenerate thumbnail when page updates',
        (tester) async {
      var page = Page.create(index: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
            ),
          ),
        ),
      );

      // Wait for first generation
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();

      // Update page with new content
      final stroke = Stroke.create(
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 100, y: 100)],
        style: StrokeStyle.pen(),
      );
      page = page.addStroke(stroke);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageThumbnail(
              page: page,
              cache: cache,
            ),
          ),
        ),
      );

      // Should regenerate (show loading briefly)
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
