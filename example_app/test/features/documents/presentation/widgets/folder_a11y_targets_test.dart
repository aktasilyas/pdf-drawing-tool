import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/breadcrumb_navigation.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_color_picker.dart';
import 'package:example_app/features/documents/presentation/widgets/inline_folder_color_row.dart';

import '../../../../helpers/l10n.dart';

Widget _host(Widget child) => localizedApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('breadcrumb back button is a labelled 48dp target',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        BreadcrumbNavigation(
          items: const [BreadcrumbItem(label: 'A'), BreadcrumbItem(label: 'B')],
          onBackPressed: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Geri'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('folder color picker swatches are named and expose selected',
      (tester) async {
    final handle = tester.ensureSemantics();
    final first = AppColors.folderColors.first.toARGB32();
    await tester.pumpWidget(
      _host(FolderColorPicker(currentColor: first)),
    );
    expect(find.bySemanticsLabel('Zümrüt'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Zümrüt')),
      isSemantics(label: 'Zümrüt', isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Mor')),
      isSemantics(label: 'Mor', isButton: true, isSelected: false),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('inline color row swatches are 48dp and labelled',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        InlineFolderColorRow(
          selectedColorValue: AppColors.folderColors.first.toARGB32(),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Pembe'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
