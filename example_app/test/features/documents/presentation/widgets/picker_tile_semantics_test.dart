import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/cover_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/sidebar_item.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grid.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/l10n/l10n.dart';
import '../../../../helpers/l10n.dart';

const _en = Locale('en');

Widget _host(Widget child, {Size size = const Size(1200, 1600)}) =>
    localizedApp(
      theme: AppTheme.light,
      locale: _en,
      builder: (context, child) => AppDrawingStringsScope(child: child!),
      home: Scaffold(
        body: SizedBox(width: size.width, height: size.height, child: child),
      ),
    );

String _coverName(Cover cover) =>
    AppDrawingStrings(lookupAppLocalizations(_en)).templates.coverName(cover);

void main() {
  void setView(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('cover tiles are named, selectable 48dp buttons', (tester) async {
    setView(tester, const Size(1200, 1600));
    final handle = tester.ensureSemantics();
    Cover? picked;
    await tester.pumpWidget(_host(CoverGridView(
      selectedCover: CoverRegistry.defaultCover,
      title: 'Biology',
      onCoverSelected: (c) => picked = c,
    )));

    final selected = _coverName(CoverRegistry.defaultCover);
    // Read once: the preview title and caption are not separate nodes.
    expect(find.bySemanticsLabel(selected), findsOneWidget);
    expect(find.bySemanticsLabel('Biology'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel(selected)),
      isSemantics(
        label: selected,
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    final other = CoverRegistry.pickable
        .firstWhere((c) => c.id != CoverRegistry.defaultCover.id);
    expect(
      tester.getSemantics(find.bySemanticsLabel(_coverName(other))),
      isSemantics(
        label: _coverName(other),
        isButton: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel(_coverName(other)));
    expect(picked?.id, other.id);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('template tiles are named, selectable 48dp buttons',
      (tester) async {
    const size = Size(390, 844);
    setView(tester, size);
    final handle = tester.ensureSemantics();
    final blank = TemplateRegistry.blank;
    await tester.pumpWidget(_host(
      TemplateGridView(
        category: TemplateCategory.basic,
        selectedTemplate: blank,
        paperColor: 0xFFFFFFFF,
        onTemplateSelected: (_) {},
      ),
      size: size,
    ));

    expect(find.bySemanticsLabel(blank.nameEn), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(blank.nameEn)),
      isSemantics(
        label: blank.nameEn,
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    final other = TemplateRegistry.getByCategory(TemplateCategory.basic)
        .firstWhere((t) => t.id != blank.id);
    expect(
      tester.getSemantics(find.bySemanticsLabel(other.nameEn)),
      isSemantics(
        label: other.nameEn,
        isButton: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('sidebar items expose button role and selected state',
      (tester) async {
    setView(tester, const Size(320, 400));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(
      Column(
        children: [
          SidebarItem(
            icon: Icons.folder_outlined,
            selectedIcon: Icons.folder,
            label: 'Work',
            isSelected: true,
            onTap: () {},
            trailing: const Text('3'),
          ),
          SidebarItem(
            icon: Icons.star_outline,
            selectedIcon: Icons.star,
            label: 'Favorites',
            isSelected: false,
            onTap: () {},
          ),
        ],
      ),
      size: const Size(320, 400),
    ));

    // Label and folder count merge into one node.
    final work = find.bySemanticsLabel(RegExp(r'^Work\n3$'));
    expect(work, findsOneWidget);
    expect(
      tester.getSemantics(work),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Favorites')),
      isSemantics(
        label: 'Favorites',
        isButton: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
