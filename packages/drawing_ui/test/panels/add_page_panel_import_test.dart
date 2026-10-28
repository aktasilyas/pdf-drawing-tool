import 'dart:async';

import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/add_page_import_helper.dart';
import 'package:drawing_ui/src/panels/add_page_panel.dart';
import 'package:drawing_ui/src/services/pdf_import_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

core.Stroke _stroke(String id) => core.Stroke(
      id: id,
      points: [
        core.DrawingPoint(x: 0, y: 0),
        core.DrawingPoint(x: 10, y: 10),
      ],
      style: core.StrokeStyle.pen(),
      createdAt: DateTime(2026),
    );

core.Page _page(String id) => core.Page(
      id: id,
      index: 0,
      size: core.PageSize.a4Portrait,
      layers: [core.Layer.empty('L')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  testWidgets(
      'import inserts into the latest document, keeps ink drawn meanwhile '
      'and undoes all imported pages at once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);

    final pending = Completer<List<core.Page>>();
    Future<List<core.Page>> fakeImporter({
      required int insertIndex,
      required core.PageSize defaultPageSize,
      void Function(PdfImportFailure failure)? onError,
      void Function(int count)? onPagesSkipped,
      void Function()? onImageError,
      core.PdfPathResolver pdfPaths = core.PdfPathResolver.passthrough,
    }) =>
        pending.future;

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pageFileImporterProvider.overrideWithValue(fakeImporter),
      ],
    );
    addTearDown(container.dispose);
    final doc = core.DrawingDocument.multiPage(
      id: 'd',
      title: 't',
      pages: [_page('p0'), _page('p1')],
      currentPageIndex: 0,
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

    final importItem = find.text('İçe aktar');
    await tester.ensureVisible(importItem);
    await tester.tap(importItem);
    await tester.pumpAndSettle();
    expect(find.byType(AddPagePanel), findsNothing);

    // Ink is drawn on page 0 while the import is still running.
    final notifier = container.read(documentProvider.notifier);
    final current = notifier.currentDocument;
    notifier.updateDocument(current.copyWith(pages: [
      current.pages[0].addStroke(_stroke('s')),
      current.pages[1],
    ]));

    pending.complete([_page('a'), _page('b')]);
    await tester.pumpAndSettle();

    var result = container.read(documentProvider);
    expect(result.pages.map((p) => p.id), ['p0', 'a', 'b', 'p1']);
    expect(result.pages[0].strokeCount, 1);
    expect(container.read(currentPageIndexProvider), 1);
    expect(find.text('Sayfa eklendi'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    result = container.read(documentProvider);
    expect(result.pages.map((p) => p.id), ['p0', 'p1']);
    expect(result.pages[0].strokeCount, 1);
  });
}
