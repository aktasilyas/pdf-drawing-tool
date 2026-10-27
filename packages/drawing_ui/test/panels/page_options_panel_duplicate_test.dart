import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

core.Page _page(String id, int index) => core.Page(
      id: id,
      index: index,
      size: core.PageSize.a4Portrait,
      layers: [core.Layer.empty('L')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late ProviderContainer container;
  late ValueNotifier<bool> panelVisible;

  Future<void> pumpPanel(WidgetTester tester, {required int pageIndex}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);

    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final doc = core.DrawingDocument.multiPage(
      id: 'd',
      title: 't',
      pages: [for (var i = 0; i < 3; i++) _page('p$i', i)],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    container.read(documentProvider.notifier).updateDocument(doc);
    container
        .read(pageManagerProvider.notifier)
        .initializeFromDocument(doc.pages, currentIndex: 0);
    panelVisible = ValueNotifier(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: panelVisible,
              builder: (_, visible, __) => visible
                  ? PageOptionsPanel(
                      // Like the popover: closing removes the panel.
                      onClose: () => panelVisible.value = false,
                      pageIndex: pageIndex,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tapItem(WidgetTester tester, String label) async {
    final item = find.text(label);
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  List<String> ids() =>
      container.read(documentProvider).pages.map((p) => p.id).toList();

  testWidgets('duplicate inserts a copy and offers undo', (tester) async {
    await pumpPanel(tester, pageIndex: 1);
    await tapItem(tester, 'Sayfayı çoğalt');

    final doc = container.read(documentProvider);
    expect(doc.pages, hasLength(4));
    expect(doc.currentPageIndex, 2);
    expect(ids().toSet(), hasLength(4));
    expect(find.text('Sayfa çoğaltıldı'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    expect(ids(), ['p0', 'p1', 'p2']);
    expect(container.read(documentProvider).currentPageIndex, 0);
    expect(container.read(pageManagerProvider).pages, hasLength(3));
  });

  testWidgets('paste inserts a fresh copy and offers undo', (tester) async {
    await pumpPanel(tester, pageIndex: 0);
    container.read(copiedPageProvider.notifier).state =
        container.read(documentProvider).pages[2];
    await tester.pump();
    await tapItem(tester, 'Sayfayı yapıştır');

    expect(ids(), hasLength(4));
    expect(ids()[1], isNot('p2'));
    expect(find.text('Sayfa yapıştırıldı'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(ids(), ['p0', 'p1', 'p2']);
  });
}
