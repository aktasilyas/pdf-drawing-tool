import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/add_page_panel_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Names that cannot come from the Turkish defaults, so the finders prove the
/// thumbnails read their labels from the strings scope.
class _EnTemplates extends TemplateStringsTr {
  const _EnTemplates();

  @override
  String templateName(Template template) => 'EN ${template.id}';
}

class _EnStrings extends DrawingStringsTr {
  const _EnStrings();

  @override
  TemplateStrings get templates => const _EnTemplates();
}

Template _template(String id) => Template(
      id: id,
      name: id,
      nameEn: id,
      category: TemplateCategory.basic,
      pattern: TemplatePattern.mediumLines,
      spacingMm: 8,
      lineWidth: 0.5,
    );

void main() {
  final templates = [_template('a'), _template('b'), _template('c')];

  Future<List<String>> pumpSection(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final selected = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DrawingStringsScope(
          strings: const _EnStrings(),
          child: AddPageTemplateSection(
            templates: templates,
            selectedId: 'b',
            onSelect: selected.add,
          ),
        ),
      ),
    ));
    return selected;
  }

  testWidgets('each thumbnail is one named button with its selected state',
      (tester) async {
    final handle = tester.ensureSemantics();
    final selected = await pumpSection(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel('EN b')),
      isSemantics(
        label: 'EN b',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('EN a')),
      isSemantics(
        label: 'EN a',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('EN c'));
    expect(selected, ['c']);
    handle.dispose();
  });

  testWidgets('template row meets tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSection(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('the whole thumbnail width is tappable', (tester) async {
    final selected = await pumpSection(tester);
    final rect = tester.getRect(find.byType(QuickTemplateThumbnail).first);

    // Below the label, at the edge of the cell: outside the painted children.
    await tester.tapAt(Offset(rect.left + 1, rect.bottom - 1));
    expect(selected, ['a']);
  });
}
