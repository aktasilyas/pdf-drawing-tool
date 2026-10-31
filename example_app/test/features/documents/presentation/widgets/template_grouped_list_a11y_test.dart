import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grouped_list.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/l10n.dart';

void main() {
  const en = Locale('en');

  Future<AppLocalizations> pumpList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localizedApp(
      locale: en,
      theme: AppTheme.light,
      home: Scaffold(
        body: TemplateGroupedList(
          paperColor: 0xFFFFFFFF,
          onTemplateSelected: (_) {},
        ),
      ),
    ));
    return tester.element(find.byType(TemplateGroupedList)).l10n;
  }

  List<TemplateCategory> nonEmptyCategories() => TemplateCategory.values
      .where((c) => TemplateRegistry.getByCategory(c).isNotEmpty)
      .toList();

  String headerLabel(AppLocalizations l10n, TemplateCategory category) =>
      '${category.displayNameEn}, '
      '${l10n.libraryTemplateCount(TemplateRegistry.getByCategory(category).length)}';

  testWidgets('header is one button with name, count and expanded state',
      (tester) async {
    final handle = tester.ensureSemantics();
    final l10n = await pumpList(tester);
    final category = nonEmptyCategories().first;
    final label = headerLabel(l10n, category);

    expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(
        label: label,
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel(label));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(
        label: label,
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('collapsed headers meet tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final l10n = await pumpList(tester);

    // Collapse every group so the headers are all on screen at once.
    for (final category in nonEmptyCategories()) {
      final label = headerLabel(l10n, category);
      await tester.scrollUntilVisible(
        find.bySemanticsLabel(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      tester.semantics.tap(find.semantics.byLabel(label));
      await tester.pumpAndSettle();
    }
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();

    for (final category in nonEmptyCategories()) {
      final rect = tester.getRect(
        find.bySemanticsLabel(headerLabel(l10n, category)),
      );
      expect(rect.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
