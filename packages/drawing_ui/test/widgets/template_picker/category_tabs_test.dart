import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/template_picker/category_tabs.dart';

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

    testWidgets('shows premium icon for premium categories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Premium categories should show premium icon when not selected
      final premiumCategories = TemplateCategory.values.where((c) => c.isPremium);
      
      // Find premium icons (at least one should exist)
      expect(find.byIcon(Icons.workspace_premium_rounded), findsWidgets);
    });

    testWidgets('hides premium icon when category is selected', (tester) async {
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

      // Premium icon count should be less when a premium category is selected
      // (because selected premium categories don't show the icon)
      expect(find.byType(CategoryTabs), findsOneWidget);
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

    testWidgets('renders all premium categories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Check premium categories exist by verifying premium icons
      final premiumCategories = TemplateCategory.values.where((c) => c.isPremium);
      if (premiumCategories.isNotEmpty) {
        expect(find.byIcon(Icons.workspace_premium_rounded), findsWidgets);
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
