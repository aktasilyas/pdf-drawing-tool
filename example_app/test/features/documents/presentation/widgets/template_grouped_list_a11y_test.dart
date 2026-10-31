import 'dart:ui' show Tristate;
import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grouped_list.dart';

import '../../../../helpers/l10n.dart';

Widget _host() => localizedApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: TemplateGroupedList(
          paperColor: 0xFFFFFFFF,
          onTemplateSelected: (_) {},
        ),
      ),
    );

SemanticsNode _firstHeader(WidgetTester tester) => tester.getSemantics(
      find.byKey(const Key('template_category_header_0')),
    );

void main() {
  testWidgets('category headers meet tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('header is one button node with name, count and expanded state',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    final node = _firstHeader(tester);
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isExpanded, Tristate.isTrue);
    expect(node.label, matches(RegExp(r'\d+')));
    expect(node.label, isNot(contains('(')));
    handle.dispose();
  });

  testWidgets('tapping header via semantics toggles expanded', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    final id = _firstHeader(tester).id;
    tester.semantics.tap(find.semantics.byPredicate((n) => n.id == id));
    await tester.pumpAndSettle();
    expect(_firstHeader(tester).flagsCollection.isExpanded, Tristate.isFalse);
    handle.dispose();
  });
}
