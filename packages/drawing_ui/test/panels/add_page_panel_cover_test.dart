import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/add_page_panel.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Before on the cover inserts at index 1', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final date = DateTime(2026);
    final doc = core.DrawingDocument.multiPage(
      id: 'd',
      title: 't',
      pages: [
        core.Page.createCover(index: 0, size: core.PageSize.a4Portrait),
        core.Page(
          id: 'p1',
          index: 1,
          size: core.PageSize.a4Portrait,
          layers: [core.Layer.empty('L')],
          createdAt: date,
          updatedAt: date,
        ),
      ],
      createdAt: date,
      updatedAt: date,
    );
    final coverId = doc.pages.first.id;
    container.read(documentProvider.notifier).updateDocument(doc);
    container
        .read(pageManagerProvider.notifier)
        .initializeFromDocument(doc.pages, currentIndex: 0);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: AddPagePanel(onClose: () {})),
        ),
      ),
    );

    await tester.tap(find.text('Önce'));
    await tester.pump();
    await tester.tap(find.byType(QuickTemplateThumbnail).first);
    await tester.pumpAndSettle();

    final pages = container.read(documentProvider).pages;
    expect(pages, hasLength(3));
    expect(pages[0].id, coverId);
    expect(pages[0].isCover, isTrue);
    expect(pages[2].id, 'p1');
  });
}
