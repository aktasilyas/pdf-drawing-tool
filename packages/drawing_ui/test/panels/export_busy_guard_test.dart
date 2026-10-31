// Every export entry point refuses to start while an export is running and
// shows the localized "export in progress" message instead (#491).
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/document_options_panel.dart';
import 'package:drawing_ui/src/panels/export_options.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _export = ExportStringsTr();

class _Runner extends PDFExportRunner {
  var runs = 0;

  @override
  Future<void> run(
    ExportProgressNotifier progress,
    core.DrawingDocument document, {
    required ExportStrings strings,
    bool isInfiniteCanvas = false,
    bool addWatermark = false,
    bool share = false,
    ExportOptions options = const ExportOptions(),
    int currentPageIndex = 0,
    PDFPageFormat? pageFormat,
  }) async {
    runs++;
  }
}

void main() {
  late ProviderContainer container;
  late _Runner runner;

  Future<void> pump(
    WidgetTester tester,
    Widget panel, {
    bool infinite = false,
    bool scroll = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);

    runner = _Runner();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      pdfExportRunnerProvider.overrideWithValue(runner),
      isInfiniteCanvasProvider.overrideWith((ref) => infinite),
    ]);
    addTearDown(container.dispose);
    container.read(documentProvider.notifier).updateDocument(
          core.DrawingDocument.emptyMultiPage('Notlar')
              .addPage(core.Page.create(index: 1)),
        );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: scroll ? SingleChildScrollView(child: panel) : panel,
        ),
      ),
    ));

    // A long export is running.
    expect(
        container.read(exportProgressProvider.notifier).tryBegin(200), isTrue);
    container.read(exportProgressProvider.notifier).updateProgress(40, 200);
  }

  Future<void> tapItem(WidgetTester tester, String label) async {
    final item = find.text(label);
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pump();
  }

  void expectRefused(WidgetTester tester) {
    expect(find.text(_export.inProgress), findsOneWidget);
    final state = container.read(exportProgressProvider);
    expect(state.status, ExportProgressStatus.exporting);
    expect(state.totalPages, 200);
    expect(state.currentPage, 40);
  }

  testWidgets('export panel: PDF export is refused with a message',
      (tester) async {
    await pump(tester, ExportPanel(onClose: () {}, embedded: true));
    await tapItem(tester, _export.exportPdf);
    expect(runner.runs, 0);
    expectRefused(tester);
  });

  testWidgets('export panel: PDF share is refused with a message',
      (tester) async {
    await pump(tester, ExportPanel(onClose: () {}, embedded: true));
    await tapItem(tester, _export.sharePdf);
    expect(runner.runs, 0);
    expectRefused(tester);
  });

  testWidgets('export panel: PNG export is refused with a message',
      (tester) async {
    await pump(
      tester,
      ExportPanel(onClose: () {}, embedded: true),
      infinite: true,
    );
    await tapItem(tester, _export.exportPng);
    expectRefused(tester);
  });

  testWidgets('document menu: PDF export is refused with a message',
      (tester) async {
    var closed = false;
    await pump(
      tester,
      DocumentOptionsPanel(
        onRename: () {},
        onDelete: () {},
        onClose: () => closed = true,
      ),
    );
    await tapItem(tester, _export.exportPdf);
    expect(closed, isTrue);
    expectRefused(tester);
  });

  testWidgets('document menu: PNG export is refused with a message',
      (tester) async {
    await pump(
      tester,
      DocumentOptionsPanel(onRename: () {}, onDelete: () {}, onClose: () {}),
      infinite: true,
    );
    await tapItem(tester, _export.exportPng);
    expectRefused(tester);
  });

  testWidgets('page menu: page PDF export is refused with a message',
      (tester) async {
    await pump(
      tester,
      PageOptionsPanel(onClose: () {}, pageIndex: 0),
      scroll: false,
    );
    await tapItem(tester, const PageStringsTr().exportPagePdf);
    expectRefused(tester);
  });

  testWidgets('no export running: the panel starts the export', (tester) async {
    await pump(tester, ExportPanel(onClose: () {}, embedded: true));
    container.read(exportProgressProvider.notifier).end();
    await tapItem(tester, _export.exportPdf);
    expect(runner.runs, 1);
    expect(find.text(_export.inProgress), findsNothing);
  });
}
