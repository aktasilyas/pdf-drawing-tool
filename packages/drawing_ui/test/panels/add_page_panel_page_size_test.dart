import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/add_page_import_helper.dart';
import 'package:drawing_ui/src/panels/add_page_panel.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';
import 'package:drawing_ui/src/services/pdf_import_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A landscape notebook as LoadDocumentUseCase builds it (1024 high).
const _landscape = core.PageSize(width: 1448, height: 1024);

core.Page _page(String id) => core.Page(
      id: id,
      index: 0,
      size: _landscape,
      background: const core.PageBackground(type: core.BackgroundType.grid),
      layers: [core.Layer.empty('L')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Future<ProviderContainer> _pumpPanel(
  WidgetTester tester, {
  core.DocumentSettings? settings,
  PageFileImporter? importer,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1400);
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (importer != null)
        pageFileImporterProvider.overrideWithValue(importer),
    ],
  );
  addTearDown(container.dispose);
  final doc = core.DrawingDocument.multiPage(
    id: 'd',
    title: 't',
    pages: [_page('p0')],
    settings: settings,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  container.read(documentProvider.notifier).updateDocument(doc);
  container
      .read(pageManagerProvider.notifier)
      .initializeFromDocument(doc.pages, currentIndex: 0);

  var open = true;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => open
                ? AddPagePanel(onClose: () => setState(() => open = false))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  for (final entry in {
    'legacy A4 settings': null,
    'notebook paper settings':
        core.DocumentSettings.defaults().copyWith(defaultPageSize: _landscape),
  }.entries) {
    testWidgets(
        'template page added to a landscape notebook (${entry.key}) '
        'matches the existing page size', (tester) async {
      final container = await _pumpPanel(tester, settings: entry.value);

      await tester.tap(find.byType(QuickTemplateThumbnail).first);
      await tester.pumpAndSettle();

      final pages = container.read(documentProvider).pages;
      expect(pages, hasLength(2));
      expect(pages[1].size, _landscape);
    });
  }

  testWidgets('import gets the notebook page size as its default',
      (tester) async {
    core.PageSize? received;
    Future<List<core.Page>> fakeImporter({
      required int insertIndex,
      required core.PageSize defaultPageSize,
      void Function(PdfImportFailure failure)? onError,
      void Function(int count)? onPagesSkipped,
      void Function(ImagePageImportError error)? onImageError,
      core.PdfPathResolver pdfPaths = core.PdfPathResolver.passthrough,
      ChoosePdfPageRange? chooseRange,
    }) async {
      received = defaultPageSize;
      return [];
    }

    await _pumpPanel(tester, importer: fakeImporter);

    final importItem = find.text('İçe aktar');
    await tester.ensureVisible(importItem);
    await tester.tap(importItem);
    await tester.pumpAndSettle();

    expect(received, _landscape);
  });

  testWidgets(
      'import hands the importer a chooser that opens the range sheet '
      'after the panel closed (AC4)', (tester) async {
    ChoosePdfPageRange? chooser;
    Future<List<core.Page>> fakeImporter({
      required int insertIndex,
      required core.PageSize defaultPageSize,
      void Function(PdfImportFailure failure)? onError,
      void Function(int count)? onPagesSkipped,
      void Function(ImagePageImportError error)? onImageError,
      core.PdfPathResolver pdfPaths = core.PdfPathResolver.passthrough,
      ChoosePdfPageRange? chooseRange,
    }) async {
      chooser = chooseRange;
      return [];
    }

    await _pumpPanel(tester, importer: fakeImporter);
    final importItem = find.text('İçe aktar');
    await tester.ensureVisible(importItem);
    await tester.tap(importItem);
    await tester.pumpAndSettle();

    expect(chooser, isNotNull);
    // The panel is gone by now; the sheet must still open and return.
    final result = chooser!(640, 500);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pdf-range-first')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pdf-range-first')));
    await tester.pumpAndSettle();
    expect(await result, const PdfPageRange(1, 500));
  });
}
