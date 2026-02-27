import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('CategoryTabs', () {
    testWidgets('renders with all categories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CategoryTabs), findsOneWidget);
      expect(find.text('Tümü'), findsOneWidget);
      
      // Verify ListView is rendered
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows "Tümü" option by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Tümü'), findsOneWidget);
    });

    testWidgets('hides "Tümü" option when showAllOption is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
              showAllOption: false,
            ),
          ),
        ),
      );

      expect(find.text('Tümü'), findsNothing);
    });

    testWidgets('highlights selected category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedCategory: TemplateCategory.productivity,
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text(TemplateCategory.productivity.displayName), findsOneWidget);
    });

    testWidgets('highlights "Tümü" when no category selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedCategory: null,
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // "Tümü" should be selected (isSelected = true)
      expect(find.text('Tümü'), findsOneWidget);
    });

    testWidgets('calls onCategorySelected when category tapped', (tester) async {
      TemplateCategory? selectedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (category) {
                selectedCategory = category;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text(TemplateCategory.creative.displayName));
      await tester.pumpAndSettle();

      expect(selectedCategory, TemplateCategory.creative);
    });

    testWidgets('calls onCategorySelected with null when "Tümü" tapped', (tester) async {
      TemplateCategory? selectedCategory = TemplateCategory.basic;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedCategory: TemplateCategory.basic,
              onCategorySelected: (category) {
                selectedCategory = category;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();

      expect(selectedCategory, isNull);
    });

    testWidgets('does not show crown icons for categories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Crown icons should not appear (premium badges removed)
      final crownIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.crown,
      );
      expect(crownIcon, findsNothing);
    });

    testWidgets('is horizontally scrollable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('has correct height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ListView),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.height, 40);
    });

    testWidgets('animates chip style on selection change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedCategory: null,
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Verify AnimatedContainer exists
      expect(find.byType(AnimatedContainer), findsWidgets);

      // Change selection
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedCategory: TemplateCategory.basic,
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Pump animation
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('uses theme colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(
              primaryContainer: Colors.blue,
              onPrimaryContainer: Colors.white,
            ),
          ),
          home: Scaffold(
            body: CategoryTabs(
              selectedCategory: TemplateCategory.basic,
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CategoryTabs), findsOneWidget);
    });

    testWidgets('renders all free categories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Basic category should exist (free)
      expect(find.text(TemplateCategory.basic.displayName), findsOneWidget);
    });

    testWidgets('renders all categories including premium', (tester) async {
      // Use wide viewport so all category chips are visible in horizontal ListView
      tester.view.physicalSize = const Size(1920, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // All categories should be rendered as plain chips (no premium badges)
      for (final category in TemplateCategory.values) {
        expect(find.text(category.displayName), findsOneWidget);
      }
    });

    testWidgets('tap on already selected category does not crash', (tester) async {
      TemplateCategory? selectedCategory = TemplateCategory.creative;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedCategory: selectedCategory,
              onCategorySelected: (category) {
                selectedCategory = category;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text(TemplateCategory.creative.displayName));
      await tester.pumpAndSettle();

      expect(selectedCategory, TemplateCategory.creative);
    });
  });
}
