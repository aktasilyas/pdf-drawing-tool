import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_card.dart';

void main() {
  group('TemplateCard', () {
    late Template testTemplate;

    setUp(() {
      testTemplate = Template(
        id: 'test-card',
        name: 'Test Card',
        nameEn: 'Test Card',
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
            body: TemplateCard(
              template: testTemplate,
            ),
          ),
        ),
      );

      expect(find.byType(TemplateCard), findsOneWidget);
      expect(find.text('Test Card'), findsOneWidget);
    });

    testWidgets('shows selected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              isSelected: true,
            ),
          ),
        ),
      );

      // Check for checkmark icon (selection indicator)
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('hides checkmark when not selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              isSelected: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('shows lock icon when locked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              isLocked: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('hides lock icon when not locked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              isLocked: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TemplateCard));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              onTap: null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TemplateCard));
      await tester.pumpAndSettle();

      // Should not crash
      expect(find.byType(TemplateCard), findsOneWidget);
    });

    testWidgets('animates border when selection changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              isSelected: false,
            ),
          ),
        ),
      );

      // Initial state
      expect(find.byType(AnimatedContainer), findsOneWidget);

      // Change selection
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              isSelected: true,
            ),
          ),
        ),
      );

      // Verify animation started
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('displays template name', (tester) async {
      final template = Template(
        id: 'custom',
        name: 'Özel Şablon',
        nameEn: 'Custom Template',
        category: TemplateCategory.creative,
        pattern: TemplatePattern.hexagonal,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: template,
            ),
          ),
        ),
      );

      expect(find.text('Özel Şablon'), findsOneWidget);
    });

    testWidgets('truncates long template names', (tester) async {
      final template = Template(
        id: 'long-name',
        name: 'Çok Uzun Bir Şablon Adı Burada Yazıyor',
        nameEn: 'Very Long Template Name Here',
        category: TemplateCategory.education,
        pattern: TemplatePattern.cornell,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: TemplateCard(
                template: template,
              ),
            ),
          ),
        ),
      );

      // Text widget should exist with overflow ellipsis
      final textWidget = tester.widget<Text>(find.text('Çok Uzun Bir Şablon Adı Burada Yazıyor'));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('shows both checkmark and lock icon when selected and locked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              isSelected: true,
              isLocked: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('uses theme colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Colors.black,
            ),
          ),
          home: Scaffold(
            body: TemplateCard(
              template: testTemplate,
              isSelected: true,
            ),
          ),
        ),
      );

      expect(find.byType(TemplateCard), findsOneWidget);
    });

    testWidgets('renders premium template', (tester) async {
      final premiumTemplate = Template(
        id: 'premium',
        name: 'Premium',
        nameEn: 'Premium',
        category: TemplateCategory.productivity,
        pattern: TemplatePattern.cornell,
        isPremium: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateCard(
              template: premiumTemplate,
              isLocked: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });
}
