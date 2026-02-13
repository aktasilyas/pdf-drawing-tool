import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('TemplateGrid', () {
    late List<Template> testTemplates;

    setUp(() {
      testTemplates = [
        Template(
          id: 'template-1',
          name: 'Template 1',
          nameEn: 'Template 1',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        ),
        Template(
          id: 'template-2',
          name: 'Template 2',
          nameEn: 'Template 2',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.mediumLines,
        ),
        Template(
          id: 'template-3',
          name: 'Template 3',
          nameEn: 'Template 3',
          category: TemplateCategory.productivity,
          pattern: TemplatePattern.cornell,
          isPremium: true,
        ),
      ];
    });

    testWidgets('renders with templates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: testTemplates,
              onTemplateSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TemplateGrid), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays all templates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: testTemplates,
              onTemplateSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TemplateCard), findsNWidgets(testTemplates.length));
    });

    testWidgets('uses 3 columns on phone width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Phone width
              child: TemplateGrid(
                templates: testTemplates,
                onTemplateSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('uses 5 columns on tablet width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800, // Tablet width
              child: TemplateGrid(
                templates: testTemplates,
                onTemplateSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.crossAxisCount, 5);
    });

    testWidgets('uses correct spacing for phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Phone width
              child: TemplateGrid(
                templates: testTemplates,
                onTemplateSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.crossAxisSpacing, 12.0);
      expect(delegate.mainAxisSpacing, 12.0);
    });

    testWidgets('uses correct spacing for tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800, // Tablet width
              child: TemplateGrid(
                templates: testTemplates,
                onTemplateSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.crossAxisSpacing, 16.0);
      expect(delegate.mainAxisSpacing, 16.0);
    });

    testWidgets('calls onTemplateSelected when template tapped', (tester) async {
      Template? selectedTemplate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: testTemplates,
              onTemplateSelected: (template) {
                selectedTemplate = template;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TemplateCard).first);
      await tester.pumpAndSettle();

      expect(selectedTemplate, testTemplates.first);
    });

    testWidgets('highlights selected template', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: testTemplates,
              selectedTemplate: testTemplates[1],
              onTemplateSelected: (_) {},
            ),
          ),
        ),
      );

      // Find the selected card by checking for the checkmark icon
      final checkIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.check,
      );
      expect(checkIcon, findsOneWidget);
    });

    testWidgets('uses isPremium by default for lock state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: testTemplates,
              onTemplateSelected: (_) {},
            ),
          ),
        ),
      );

      // Premium template should show lock icon
      final lockIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.lock,
      );
      expect(lockIcon, findsOneWidget);
    });

    testWidgets('uses custom isLocked callback when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: testTemplates,
              onTemplateSelected: (_) {},
              isLocked: (template) => template.id == 'template-1',
            ),
          ),
        ),
      );

      // Only first template should be locked
      final lockIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.lock,
      );
      expect(lockIcon, findsOneWidget);
    });

    testWidgets('handles empty template list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: [],
              onTemplateSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TemplateCard), findsNothing);
    });

    testWidgets('has correct aspect ratio for phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TemplateGrid(
                templates: testTemplates,
                onTemplateSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.childAspectRatio, 0.72);
    });

    testWidgets('has correct aspect ratio for tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: TemplateGrid(
                templates: testTemplates,
                onTemplateSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.childAspectRatio, 0.75);
    });

    testWidgets('uses LayoutBuilder for responsive design', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: testTemplates,
              onTemplateSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('switches from phone to tablet layout', (tester) async {
      // Start with phone width
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TemplateGrid(
                templates: testTemplates,
                onTemplateSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      var gridView = tester.widget<GridView>(find.byType(GridView));
      var delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);

      // Change to tablet width
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: TemplateGrid(
                templates: testTemplates,
                onTemplateSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      gridView = tester.widget<GridView>(find.byType(GridView));
      delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 5);
    });

    testWidgets('renders with many templates', (tester) async {
      final manyTemplates = List.generate(
        20,
        (index) => Template(
          id: 'template-$index',
          name: 'Template $index',
          nameEn: 'Template $index',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: manyTemplates,
              onTemplateSelected: (_) {},
            ),
          ),
        ),
      );

      // Should build all items (even if not visible)
      expect(find.byType(TemplateCard), findsWidgets);
    });

    testWidgets('null selectedTemplate shows no selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateGrid(
              templates: testTemplates,
              selectedTemplate: null,
              onTemplateSelected: (_) {},
            ),
          ),
        ),
      );

      final checkIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.check,
      );
      expect(checkIcon, findsNothing);
    });
  });
}
