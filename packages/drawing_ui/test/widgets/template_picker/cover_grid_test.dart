import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _EnTemplates extends TemplateStringsTr {
  const _EnTemplates();

  @override
  String coverName(Cover cover) => 'EN ${cover.id}';
}

class _EnStrings extends DrawingStringsTr {
  const _EnStrings();

  @override
  TemplateStrings get templates => const _EnTemplates();
}

Widget _host({DrawingStrings? strings, double textScale = 1}) {
  final grid = CoverGrid(
    covers: CoverRegistry.pickable,
    selectedCover: CoverRegistry.defaultCover,
    onCoverSelected: (_) {},
  );
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: strings == null
          ? grid
          : DrawingStringsScope(strings: strings, child: grid),
    ),
  );
}

void main() {
  group('TemplateStringsTr.coverName', () {
    const s = TemplateStringsTr();

    test('family covers get Turkish names', () {
      expect(s.coverName(CoverFamily.linenSage), 'Adaçayı Keten');
      expect(s.coverName(CoverFamily.feltDustyRose), 'Gül Kurusu Keçe');
      for (final cover in CoverFamily.all) {
        expect(s.coverName(cover), isNot(cover.name), reason: cover.id);
        expect(s.coverName(cover).trim(), isNotEmpty, reason: cover.id);
      }
    });

    test('legacy registry covers keep their Turkish names', () {
      expect(s.coverName(CoverRegistry.solidNavy), 'Lacivert');
      expect(s.coverName(CoverRegistry.imageCoverLeather), 'Deri');
    });

    test('unknown ids fall back to Cover.name', () {
      const unknown = Cover(
        id: 'unknown_cover',
        name: 'Mystery',
        style: CoverStyle.solid,
        primaryColor: 0xFF000000,
      );
      expect(s.coverName(unknown), 'Mystery');
    });
  });

  group('CoverGrid', () {
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('shows Turkish names without a scope', (tester) async {
      phone(tester);
      await tester.pumpWidget(_host());
      expect(find.text('Adaçayı Keten'), findsOneWidget);
      expect(find.text(CoverFamily.linenSage.name), findsNothing);
    });

    testWidgets('label and semantics follow the strings scope',
        (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(strings: const _EnStrings()));
      expect(find.text('EN linen_sage'), findsOneWidget);
      expect(find.bySemanticsLabel('EN linen_sage'), findsOneWidget);
      expect(find.text('Adaçayı Keten'), findsNothing);
      handle.dispose();
    });

    testWidgets('no overflow on a phone at text scale 1.3', (tester) async {
      phone(tester);
      await tester.pumpWidget(_host(textScale: 1.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
