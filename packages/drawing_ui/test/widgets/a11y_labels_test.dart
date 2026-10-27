import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/widgets/floating_pen_box_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _presets = [
  PenPreset(id: 'ballpoint'),
  PenPreset(
    id: 'highlighter',
    toolType: ToolType.highlighter,
    color: Color(0xFFFFD54F),
  ),
];

Widget _app(Widget child, {ProviderContainer? container}) {
  final app = MaterialApp(
    home: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
  if (container == null) return app;
  return UncontrolledProviderScope(container: container, child: app);
}

void main() {
  group('colorSemanticsLabel', () {
    test('formats RGB hex without alpha', () {
      expect(colorSemanticsLabel(const Color(0x801565C0)), 'Renk #1565C0');
      expect(colorSemanticsLabel(const Color(0xFF000000)), 'Renk #000000');
    });
  });

  group('FloatingPenBox', () {
    Future<void> pumpBox(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          penBoxPresetsProvider
              .overrideWith((ref) => PenBoxPresetsNotifier(_presets)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(
        const FloatingPenBox(position: Offset(12, 12)),
        container: container,
      ));
    }

    testWidgets('pens and controls are labelled buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBox(tester);

      expect(find.bySemanticsLabel('Fosforlu Kalem, Renk #FFD54F'),
          findsOneWidget);
      expect(find.bySemanticsLabel('Kalem kutusunu düzenle'), findsOneWidget);
      expect(find.bySemanticsLabel('Kalem kutusunu daralt'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.tap(find.byIcon(ElyanotesIcons.editPencil));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Kalemi kaldır'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Düzenlemeyi bitir'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('collapsed box announces the pen count', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBox(tester);
      await tester.tap(find.byIcon(ElyanotesIcons.caretUp));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingPenBoxCollapsed), findsOneWidget);
      expect(find.bySemanticsLabel('Kalem kutusu, 2 kalem'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  testWidgets('ZoomControlBar controls are labelled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final handle = tester.ensureSemantics();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _app(const ZoomControlBar(), container: container),
    );
    container.read(isZoomingProvider.notifier).state = true;
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Yakınlaştırma kilidi'), findsOneWidget);
    expect(find.bySemanticsLabel('Favori yakınlaştırma'), findsOneWidget);
    expect(
        find.bySemanticsLabel(RegExp(r'^Yakınlaştırma \d+%')), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    // The favourites dropdown items are labelled by their text.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Yakınlaştırma \d+%')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('150%'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  group('PageThumbnail', () {
    testWidgets('tappable thumbnail announces page and selection',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(
        PageThumbnail(
          page: core.Page.create(index: 1),
          cache: ThumbnailCache(maxSize: 4),
          isSelected: true,
          onTap: () {},
        ),
      ));
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Sayfa 2')),
        containsSemantics(label: 'Sayfa 2', isButton: true, isSelected: true),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('thumbnail without handlers adds no label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(
        PageThumbnail(
          page: core.Page.create(index: 1),
          cache: ThumbnailCache(maxSize: 4),
        ),
      ));
      await tester.pump();

      expect(find.bySemanticsLabel('Sayfa 2'), findsNothing);
      handle.dispose();
    });
  });

  testWidgets('colour chips and swatches are labelled and selectable',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(
      Column(
        children: [
          ColorChip(
            color: const Color(0xFF1565C0),
            isSelected: true,
            onTap: () {},
          ),
          SizedBox(
            width: 300,
            child: ColorSwatchGrid(
              selectedColor: Colors.black,
              onColorSelected: (_) {},
            ),
          ),
        ],
      ),
    ));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Renk #1565C0')),
      containsSemantics(isButton: true, isSelected: true),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
