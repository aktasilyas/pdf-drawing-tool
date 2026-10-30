import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Labels that cannot come from the Turkish defaults, so the finders below
/// prove the widgets read their names from the strings scope.
class _EnTemplates extends TemplateStringsTr {
  const _EnTemplates();

  @override
  String get allCategories => 'EN all';

  @override
  String templateName(Template template) => 'EN ${template.id}';

  @override
  String categoryName(TemplateCategory category) => 'EN ${category.name}';
}

class _EnStrings extends DrawingStringsTr {
  const _EnStrings();

  @override
  TemplateStrings get templates => const _EnTemplates();
}

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: DrawingStringsScope(strings: const _EnStrings(), child: child),
      ),
    );

final _template = Template(
  id: 'sem-card',
  name: 'Kart',
  nameEn: 'Card',
  category: TemplateCategory.basic,
  pattern: TemplatePattern.mediumLines,
  spacingMm: 8,
  lineWidth: 0.5,
);

void main() {
  void wide(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('TemplateCard semantics', () {
    testWidgets('is one named, selected button', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(_host(SizedBox(
        width: 120,
        height: 160,
        child: TemplateCard(
          template: _template,
          isSelected: true,
          onTap: () => taps++,
        ),
      )));

      final node = find.bySemanticsLabel('EN sem-card');
      expect(node, findsOneWidget);
      expect(
        tester.getSemantics(node),
        isSemantics(
          label: 'EN sem-card',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );

      tester.semantics.tap(node);
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('unselected card reports selected: false', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(SizedBox(
        width: 120,
        height: 160,
        child: TemplateCard(template: _template, onTap: () {}),
      )));

      expect(
        tester.getSemantics(find.bySemanticsLabel('EN sem-card')),
        isSemantics(
          label: 'EN sem-card',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Center(
        child: SizedBox(
          width: 120,
          height: 160,
          child: TemplateCard(template: _template, onTap: () {}),
        ),
      )));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('CategoryTabs semantics', () {
    testWidgets('chips are named buttons; only the active one is selected',
        (tester) async {
      wide(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(CategoryTabs(
        selectedCategory: TemplateCategory.creative,
        onCategorySelected: (_) {},
      )));

      expect(
        tester.getSemantics(find.bySemanticsLabel('EN creative')),
        isSemantics(
          label: 'EN creative',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('EN all')),
        isSemantics(
          label: 'EN all',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('semantic tap selects the category', (tester) async {
      wide(tester);
      final handle = tester.ensureSemantics();
      TemplateCategory? picked = TemplateCategory.basic;
      await tester.pumpWidget(_host(CategoryTabs(
        selectedCategory: TemplateCategory.basic,
        onCategorySelected: (c) => picked = c,
      )));

      tester.semantics.tap(find.bySemanticsLabel('EN productivity'));
      expect(picked, TemplateCategory.productivity);
      tester.semantics.tap(find.bySemanticsLabel('EN all'));
      expect(picked, isNull);
      handle.dispose();
    });

    testWidgets('chips are at least 48dp tall and pass the guidelines',
        (tester) async {
      wide(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(CategoryTabs(onCategorySelected: (_) {})));

      final size = tester.getSize(find.bySemanticsLabel('EN all'));
      expect(size.height, greaterThanOrEqualTo(48));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tapping the row outside the chip pill still selects it',
        (tester) async {
      wide(tester);
      final handle = tester.ensureSemantics();
      TemplateCategory? picked = TemplateCategory.basic;
      await tester.pumpWidget(_host(CategoryTabs(
        selectedCategory: TemplateCategory.basic,
        onCategorySelected: (c) => picked = c,
      )));

      // The 40dp pill is centred in the 48dp target; tap 2dp from its top.
      final rect = tester.getRect(find.bySemanticsLabel('EN all'));
      await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
      expect(picked, isNull);
      handle.dispose();
    });
  });
}
