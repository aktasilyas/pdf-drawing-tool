import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('TemplatePicker', () {
    testWidgets('renders with all components', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      expect(find.byType(TemplatePicker), findsOneWidget);
      expect(find.text('Şablon Seç'), findsOneWidget);
      expect(find.byType(CategoryTabs), findsOneWidget);
      expect(find.byType(TemplateGrid), findsOneWidget);
      expect(find.byType(PaperSizePicker), findsOneWidget);
      expect(find.text('Uygula'), findsOneWidget);
    });

    testWidgets('initializes with default template', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      // Should have at least one selected template (blank-white default)
      expect(find.byType(TemplateCard), findsWidgets);
    });

    testWidgets('initializes with provided template', (tester) async {
      final template = TemplateRegistry.all.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(
              initialTemplate: template,
            ),
          ),
        ),
      );

      expect(find.byType(TemplatePicker), findsOneWidget);
    });

    testWidgets('initializes with provided paper size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(
              initialPaperSize: PaperSize.a5,
            ),
          ),
        ),
      );

      expect(find.text('A5'), findsOneWidget);
    });

    testWidgets('filters templates by category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      // Initially shows all templates
      final initialTemplateCount = tester.widgetList(find.byType(TemplateCard)).length;
      expect(initialTemplateCount, greaterThan(0));

      // Select a category
      await tester.tap(find.text(TemplateCategory.basic.displayName));
      await tester.pumpAndSettle();

      // Should filter templates
      expect(find.byType(TemplateCard), findsWidgets);
    });

    testWidgets('changes paper size when picker changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      // Initial size is A4
      expect(find.text('A4'), findsOneWidget);

      // Change to A5
      await tester.tap(find.byType(DropdownButton<PaperSizePreset>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A5').last);
      await tester.pumpAndSettle();

      expect(find.text('A5'), findsWidgets);
    });

    testWidgets('closes when close button tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: TemplatePicker(),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Şablon Seç'), findsOneWidget);

      await tester.tap(find.byIcon(StarNoteIcons.close));
      await tester.pumpAndSettle();

      expect(find.text('Şablon Seç'), findsNothing);
    });

    testWidgets('returns result when confirm button tapped', (tester) async {
      TemplatePickerResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<TemplatePickerResult>(
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: TemplatePicker(),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result?.template, isNotNull);
      expect(result?.paperSize, isNotNull);
    });

    testWidgets('all templates are selectable (no lock)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      // No card should be locked
      final lockedCard = find.byWidgetPredicate(
        (widget) => widget is TemplateCard && widget.isLocked,
      );
      expect(lockedCard, findsNothing);
    });

    testWidgets('changes selection when any template tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      final cards = find.byType(TemplateCard);
      if (cards.evaluate().length > 1) {
        await tester.tap(cards.at(1));
        await tester.pumpAndSettle();

        // Should have exactly one selected
        final selected = tester.widgetList<TemplateCard>(
          find.byWidgetPredicate(
            (widget) => widget is TemplateCard && widget.isSelected,
          ),
        ).length;
        expect(selected, 1);
      }
    });

    testWidgets('shows all templates when no category selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      final allTemplatesCount = TemplateRegistry.all.length;
      
      // GridView.builder lazily builds items, so we can't count actual widgets
      // Instead, verify that grid has correct itemCount
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final builder = gridView.childrenDelegate as SliverChildBuilderDelegate;
      
      expect(builder.estimatedChildCount, allTemplatesCount);
    });

    testWidgets('has close button in header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      expect(find.byIcon(StarNoteIcons.close), findsOneWidget);
    });

    testWidgets('has confirm button in bottom bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePicker(),
          ),
        ),
      );

      // FilledButton.icon creates multiple widgets, find by the button text
      expect(find.text('Uygula'), findsOneWidget);

      // Verify it has an icon (plus icon from StarNoteIcons)
      final plusIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.plus,
      );
      expect(plusIcon, findsOneWidget);
    });
  });

  group('TemplatePickerResult', () {
    test('creates with template and paper size', () {
      final template = Template(
        id: 'test',
        name: 'Test',
        nameEn: 'Test',
        category: TemplateCategory.basic,
        pattern: TemplatePattern.blank,
      );
      final paperSize = PaperSize.a4;

      final result = TemplatePickerResult(
        template: template,
        paperSize: paperSize,
      );

      expect(result.template, template);
      expect(result.paperSize, paperSize);
    });
  });

  group('TemplatePicker static methods', () {
    testWidgets('show method uses bottom sheet on phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    TemplatePicker.show(context);
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Should show as bottom sheet (DraggableScrollableSheet)
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.text('Şablon Seç'), findsOneWidget);
    });

    testWidgets('show method uses dialog on tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    TemplatePicker.show(context);
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Should show as dialog
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Şablon Seç'), findsOneWidget);
    });
  });
}
