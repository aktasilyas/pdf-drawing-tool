import 'package:drawing_core/drawing_core.dart' show DrawingDocument, Page;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/export_options.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:drawing_ui/src/panels/page_options_rows.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../golden/helpers/chrome_theme.dart';

const _s = ExportStringsTr();

class _Runner extends PDFExportRunner {
  final runs = <ExportOptions>[];
  final currentIndexes = <int>[];
  final infinite = <bool>[];

  @override
  Future<void> run(
    ExportProgressNotifier progress,
    DrawingDocument document, {
    required ExportStrings strings,
    bool isInfiniteCanvas = false,
    bool addWatermark = false,
    bool share = false,
    ExportOptions options = const ExportOptions(),
    int currentPageIndex = 0,
  }) async {
    runs.add(options);
    currentIndexes.add(currentPageIndex);
    infinite.add(isInfiniteCanvas);
  }
}

class _MockExporter extends Mock implements PDFExporter {}

class _FakeOptions extends Fake implements PDFExportOptions {}

void main() {
  final pages = [for (var i = 0; i < 5; i++) Page.create(index: i)];

  setUpAll(() => registerFallbackValue(_FakeOptions()));

  Future<_Runner> pump(WidgetTester tester) async {
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
        currentPageIndexProvider.overrideWithValue(3),
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
    return runner;
  }

  Future<void> enterRange(WidgetTester tester, String from, String to) async {
    await tester.tap(find.text(_s.scopeRange));
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('export-range-from')), from);
    await tester.enterText(find.byKey(const ValueKey('export-range-to')), to);
    await tester.pump();
  }

  VoidCallback? exportAction(WidgetTester tester) => tester
      .widget<PageOptionsMenuItem>(
          find.widgetWithText(PageOptionsMenuItem, _s.exportPdf))
      .onTap;

  testWidgets('Range 2-4 reaches the runner and selects pages 2, 3, 4',
      (tester) async {
    final runner = await pump(tester);
    await enterRange(tester, '2', '4');
    expect(find.textContaining('arasında olmalı'), findsNothing);

    await tester.tap(find.text(_s.exportPdf));
    await tester.pump();

    final o = runner.runs.single;
    expect(o.scope, ExportPageScope.range);
    expect(o.from, 2);
    expect(o.to, 4);
    expect(o.select(pages, runner.currentIndexes.single).map((p) => p.id),
        [pages[1].id, pages[2].id, pages[3].id]);
  });

  testWidgets('Current page selects exactly the current page', (tester) async {
    final runner = await pump(tester);
    await tester.tap(find.text(_s.scopeCurrent));
    await tester.pump();
    await tester.tap(find.text(_s.exportPdf));
    await tester.pump();

    final o = runner.runs.single;
    expect(o.scope, ExportPageScope.current);
    expect(runner.currentIndexes.single, 3);
    expect(runner.infinite.single, isFalse,
        reason: 'the canvas mode must reach the runner');
    expect(o.select(pages, runner.currentIndexes.single).map((p) => p.id),
        [pages[3].id]);
  });

  for (final c in [('0', '3'), ('2', '9'), ('4', '2')]) {
    testWidgets('invalid range ${c.$1}-${c.$2} shows message, disables export',
        (tester) async {
      final runner = await pump(tester);
      await enterRange(tester, c.$1, c.$2);

      expect(find.textContaining('arasında olmalı'), findsOneWidget);
      expect(exportAction(tester), isNull);
      await tester.tap(find.text(_s.exportPdf));
      await tester.tap(find.text(_s.sharePdf));
      await tester.pump();
      expect(runner.runs, isEmpty);
    });
  }

  group('performPDFExport maps options to the exporter', () {
    Future<PDFExportOptions> exportWith(ExportOptions options,
        {bool infinite = false}) async {
      final exporter = _MockExporter();
      when(() => exporter.exportPages(
                pages: any(named: 'pages'),
                metadata: any(named: 'metadata'),
                options: any(named: 'options'),
                onProgress: any(named: 'onProgress'),
                isCancelled: any(named: 'isCancelled'),
              ))
          .thenAnswer((_) async => PDFExportResult.error(ExportFailure.failed));
      final doc = DrawingDocument.multiPage(
        id: 'd',
        title: 'T',
        pages: pages,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      await performPDFExport(
        ExportProgressNotifier(),
        doc,
        strings: _s,
        isInfiniteCanvas: infinite,
        options: options,
        currentPageIndex: 1,
        exporter: exporter,
      );
      final captured = verify(() => exporter.exportPages(
            pages: any(named: 'pages'),
            metadata: any(named: 'metadata'),
            options: captureAny(named: 'options'),
            onProgress: any(named: 'onProgress'),
            isCancelled: any(named: 'isCancelled'),
          )).captured;
      return captured.single as PDFExportOptions;
    }

    test('template off becomes includeBackground false', () async {
      final o = await exportWith(const ExportOptions(includeTemplate: false));
      expect(o.includeBackground, isFalse);
    });

    test('template on keeps includeBackground true', () async {
      final o = await exportWith(const ExportOptions());
      expect(o.includeBackground, isTrue);
    });

    test('canvas mode becomes isInfiniteCanvas', () async {
      expect((await exportWith(const ExportOptions())).isInfiniteCanvas,
          isFalse);
      final o = await exportWith(const ExportOptions(), infinite: true);
      expect(o.isInfiniteCanvas, isTrue);
    });
  });
}
