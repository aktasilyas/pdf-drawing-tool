import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/template_category_tabs.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grid.dart';
import 'package:example_app/l10n/l10n.dart';
import '../../../../helpers/l10n.dart';

Widget _host(Widget child, Locale locale) => localizedApp(
      locale: locale,
      theme: AppTheme.light,
      home: Scaffold(body: SizedBox(width: 390, height: 800, child: child)),
    );

void main() {
  void phoneView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  const en = Locale('en');
  const tr = Locale('tr');

  group('TemplateCategoryTabs', () {
    testWidgets('en shows English labels', (tester) async {
      phoneView(tester);
      await tester.pumpWidget(_host(
        TemplateCategoryTabs(
          selectedCategory: null,
          onCategorySelected: (_) {},
        ),
        en,
      ));
      final l10n = tester.element(find.byType(TemplateCategoryTabs)).l10n;
      expect(find.text(l10n.libraryTemplateCategoryAll), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text(TemplateCategory.basic.displayNameEn), findsOneWidget);
      expect(find.text(TemplateCategory.basic.displayName), findsNothing);
    });

    testWidgets('tr shows Turkish labels', (tester) async {
      phoneView(tester);
      await tester.pumpWidget(_host(
        TemplateCategoryTabs(
          selectedCategory: null,
          onCategorySelected: (_) {},
        ),
        tr,
      ));
      expect(find.text('Hepsi'), findsOneWidget);
      expect(find.text(TemplateCategory.basic.displayName), findsOneWidget);
    });
  });

  group('TemplateGridView', () {
    testWidgets('en shows nameEn of templates', (tester) async {
      phoneView(tester);
      await tester.pumpWidget(_host(
        TemplateGridView(
          category: TemplateCategory.basic,
          paperColor: 0xFFFFFFFF,
          onTemplateSelected: (_) {},
        ),
        en,
      ));
      expect(find.text(TemplateRegistry.blank.nameEn), findsOneWidget);
      expect(find.text(TemplateRegistry.blank.name), findsNothing);
    });

    testWidgets('tr shows name of templates', (tester) async {
      phoneView(tester);
      await tester.pumpWidget(_host(
        TemplateGridView(
          category: TemplateCategory.basic,
          paperColor: 0xFFFFFFFF,
          onTemplateSelected: (_) {},
        ),
        tr,
      ));
      expect(find.text(TemplateRegistry.blank.name), findsOneWidget);
    });

    testWidgets('grouped list follows the locale', (tester) async {
      phoneView(tester);
      await tester.pumpWidget(_host(
        TemplateGridView(
          category: null,
          paperColor: 0xFFFFFFFF,
          onTemplateSelected: (_) {},
        ),
        en,
      ));
      expect(find.text(TemplateCategory.basic.displayNameEn), findsOneWidget);
      expect(find.text(TemplateRegistry.blank.nameEn), findsOneWidget);
    });
  });
}
