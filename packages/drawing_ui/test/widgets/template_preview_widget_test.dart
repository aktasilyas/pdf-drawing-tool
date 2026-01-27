import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/template_preview_widget.dart';

void main() {
  group('TemplatePreviewWidget', () {
    late Template testTemplate;

    setUp(() {
      testTemplate = Template(
        id: 'test-template',
        name: 'Test Template',
        nameEn: 'Test Template',
        category: TemplateCategory.basic,
        pattern: TemplatePattern.mediumLines,
        spacingMm: 8,
        lineWidth: 0.5,
      );
    });

    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
            ),
          ),
        ),
      );

      expect(find.byType(TemplatePreviewWidget), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('uses provided size', (tester) async {
      const customSize = Size(300, 400);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
              size: customSize,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.constraints?.maxWidth, customSize.width);
      expect(container.constraints?.maxHeight, customSize.height);
    });

    testWidgets('applies custom border radius', (tester) async {
      const customRadius = BorderRadius.all(Radius.circular(16));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
              borderRadius: customRadius,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.borderRadius, customRadius);
    });

    testWidgets('respects showBorder flag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
              showBorder: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    });

    testWidgets('shows border when showBorder is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
              showBorder: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });

    testWidgets('uses theme colors by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(),
          ),
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts color overrides', (tester) async {
      const lineColorOverride = Colors.red;
      const backgroundColorOverride = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
              lineColorOverride: lineColorOverride,
              backgroundColorOverride: backgroundColorOverride,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders different template patterns', (tester) async {
      final patterns = [
        TemplatePattern.blank,
        TemplatePattern.mediumGrid,
        TemplatePattern.smallDots,
        TemplatePattern.isometric,
      ];

      for (final pattern in patterns) {
        final template = Template(
          id: 'test-$pattern',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: pattern,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TemplatePreviewWidget(
                template: template,
              ),
            ),
          ),
        );

        expect(find.byType(TemplatePreviewWidget), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    testWidgets('applies box shadow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.boxShadow, isNotNull);
      expect(decoration?.boxShadow?.length, 1);
    });

    testWidgets('uses antialiasing clip behavior', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: testTemplate,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.clipBehavior, Clip.antiAlias);
    });

    testWidgets('handles complex templates with extraData', (tester) async {
      final cornellTemplate = Template(
        id: 'cornell-test',
        name: 'Cornell',
        nameEn: 'Cornell',
        category: TemplateCategory.productivity,
        pattern: TemplatePattern.cornell,
        isPremium: true,
        extraData: {
          'marginLeft': 80.0,
          'marginBottom': 60.0,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatePreviewWidget(
              template: cornellTemplate,
            ),
          ),
        ),
      );

      expect(find.byType(TemplatePreviewWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
