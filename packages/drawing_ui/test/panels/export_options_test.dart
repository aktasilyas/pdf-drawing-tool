import 'package:drawing_core/drawing_core.dart' show DrawingDocument, Page;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/export_options.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../golden/helpers/chrome_theme.dart';

class _Runner extends PDFExportRunner {
  final runs = <ExportOptions>[];
  final currentIndexes = <int>[];

  @override
  Future<void> run(
    ExportProgressNotifier progress,
    DrawingDocument document, {
    bool addWatermark = false,
    bool share = false,
    ExportOptions options = const ExportOptions(),
    int currentPageIndex = 0,
  }) async {
    runs.add(options);
    currentIndexes.add(currentPageIndex);
  }
}

void main() {
  test('select returns current page and range pages', () {
    final pages = [for (var i = 0; i < 5; i++) Page.create(index: i)];
    expect(
      const ExportOptions(scope: ExportPageScope.current)
          .select(pages, 2)
          .map((p) => p.id),
      [pages[2].id],
    );
    expect(
      const ExportOptions(scope: ExportPageScope.range, from: 2, to: 4)
          .select(pages, 0)
          .map((p) => p.id),
      [pages[1].id, pages[2].id, pages[3].id],
    );
  });

  test('isValid rejects 0, beyond count and from > to', () {
    ExportOptions r(int a, int b) =>
        ExportOptions(scope: ExportPageScope.range, from: a, to: b);
    expect(r(0, 2).isValid(5), isFalse);
    expect(r(1, 6).isValid(5), isFalse);
    expect(r(4, 2).isValid(5), isFalse);
    expect(r(2, 4).isValid(5), isTrue);
  });

  testWidgets('invalid range disables export, template off is forwarded',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final runner = _Runner();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pdfExportRunnerProvider.overrideWithValue(runner),
        isInfiniteCanvasProvider.overrideWith((ref) => false),
      ],
      child: MaterialApp(
        theme: chromeTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExportPanel(onClose: () {}, embedded: true),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Aralık'));
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('export-range-from')), '0');
    await tester.pump();
    expect(find.textContaining('arasında olmalı'), findsOneWidget);
    await tester.tap(find.text('PDF Olarak Dışa Aktar'));
    await tester.pump();
    expect(runner.runs, isEmpty);

    await tester.enterText(
        find.byKey(const ValueKey('export-range-from')), '1');
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('PDF Olarak Dışa Aktar'));
    await tester.pump();
    expect(runner.runs.single.includeTemplate, isFalse);
    expect(runner.runs.single.scope, ExportPageScope.range);
  });

  testWidgets('Bu sayfa exports the current page only', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final runner = _Runner();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pdfExportRunnerProvider.overrideWithValue(runner),
        isInfiniteCanvasProvider.overrideWith((ref) => false),
        pageCountProvider.overrideWithValue(5),
        currentPageIndexProvider.overrideWithValue(2),
      ],
      child: MaterialApp(
        theme: chromeTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExportPanel(onClose: () {}, embedded: true),
          ),
        ),
      ),
    ));

    // Every option is a >= 48dp touch target.
    for (final finder in [
      find.byType(SegmentedButton<ExportPageScope>),
      find.byType(SwitchListTile),
    ]) {
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
    }

    await tester.tap(find.text('Bu sayfa'));
    await tester.pump();
    await tester.tap(find.text('PDF Olarak Dışa Aktar'));
    await tester.pump();
    expect(runner.runs.single.scope, ExportPageScope.current);
    expect(runner.currentIndexes.single, 2);
    final pages = [for (var i = 0; i < 5; i++) Page.create(index: i)];
    expect(runner.runs.single.select(pages, 2).single.id, pages[2].id);
  });

  testWidgets('switching scope keeps a valid range', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isInfiniteCanvasProvider.overrideWith((ref) => false),
        pageCountProvider.overrideWithValue(5),
      ],
      child: MaterialApp(
        theme: chromeTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExportPanel(
              onClose: () {},
              embedded: true,
              initialOptions: const ExportOptions(
                  scope: ExportPageScope.range, from: 2, to: 3),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Tümü'));
    await tester.pump();
    await tester.tap(find.text('Aralık'));
    await tester.pump();
    final to = tester.widget<TextField>(find.descendant(
        of: find.byKey(const ValueKey('export-range-to')),
        matching: find.byType(TextField)));
    expect(to.controller!.text, '3');
  });

  // CI goldens draw editable text as a plain block, so the range digits'
  // colour is checked here instead.
  testWidgets('range digits use the on-surface colour in dark mode',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final theme = chromeTheme(Brightness.dark);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isInfiniteCanvasProvider.overrideWith((ref) => false),
        pageCountProvider.overrideWithValue(5),
      ],
      child: MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExportPanel(
              onClose: () {},
              embedded: true,
              initialOptions: const ExportOptions(
                  scope: ExportPageScope.range, from: 2, to: 4),
            ),
          ),
        ),
      ),
    ));

    for (final key in ['export-range-from', 'export-range-to']) {
      final editable = tester.widget<EditableText>(find.descendant(
          of: find.byKey(ValueKey(key)), matching: find.byType(EditableText)));
      expect(editable.style.color, theme.colorScheme.onSurface);
    }
  });
}
