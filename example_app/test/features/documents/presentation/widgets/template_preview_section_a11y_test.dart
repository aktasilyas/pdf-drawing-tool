import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/format_picker_sheet.dart';
import 'package:example_app/features/documents/presentation/widgets/template_preview_section.dart';

import '../../../../helpers/l10n.dart';

Widget _host({ValueChanged<bool>? onCoverToggle}) => localizedApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TemplatePreviewSection(
            hasCover: true,
            isSelectingCover: false,
            paperSize: PaperSize.a4,
            paperColor: 0xFFFFFFFF,
            title: '',
            cover: CoverFamily.linenSage,
            template: null,
            onCoverToggle: onCoverToggle ?? (_) {},
            onSelectingCoverChanged: (_) {},
            onTitleChanged: (_) {},
            onPaperSizeChanged: (_) {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('cover switch and format button meet tap target guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('cover switch toggles via a single labelled semantics node',
      (tester) async {
    final handle = tester.ensureSemantics();
    bool? toggled;
    await tester.pumpWidget(_host(onCoverToggle: (v) => toggled = v));
    final node =
        tester.getSemantics(find.byKey(const Key('template_cover_switch')));
    expect(node.label, contains('Kapak'));
    tester.semantics.tap(find.semantics.byPredicate((n) => n.id == node.id));
    await tester.pump();
    expect(toggled, isFalse);
    handle.dispose();
  });

  testWidgets('format button is a button and opens the picker', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    final node =
        tester.getSemantics(find.byKey(const Key('template_format_button')));
    expect(node.flagsCollection.isButton, isTrue);
    await tester.tap(find.byKey(const Key('template_format_button')));
    await tester.pumpAndSettle();
    expect(find.byType(FormatPickerSheet), findsOneWidget);
    handle.dispose();
  });
}
