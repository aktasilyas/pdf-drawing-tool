import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
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

/// Two pages with one stroke each; page 0 is current.
core.DrawingDocument _twoPagesWithInk() {
  final base = core.DrawingDocument.emptyMultiPage('Test')
      .addPage(core.Page.create(index: 1));
  final pages = [
    base.pages[0].addStroke(_stroke('a')),
    base.pages[1].addStroke(_stroke('b')),
  ];
  return base.copyWith(pages: pages, currentPageIndex: 0);
}

void main() {
  testWidgets('clear from a non-current thumbnail targets that page',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(documentProvider.notifier);
    notifier.updateDocument(_twoPagesWithInk());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: PageOptionsPanel(onClose: () {}, pageIndex: 1),
          ),
        ),
      ),
    );

    final clearItem = find.text('Sayfayı temizle');
    await tester.ensureVisible(clearItem);
    await tester.tap(clearItem);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sayfa 2 temizlensin mi?'), findsOneWidget);
    await tester.tap(find.text('Temizle'));
    await tester.pumpAndSettle();

    var doc = container.read(documentProvider);
    expect(doc.pages[0].strokeCount, 1);
    expect(doc.pages[1].strokeCount, 0);
    expect(doc.currentPageIndex, 0);

    container.read(historyManagerProvider.notifier).undo();

    doc = container.read(documentProvider);
    expect(doc.pages[0].strokeCount, 1);
    expect(doc.pages[1].strokeCount, 1);
  });
}
