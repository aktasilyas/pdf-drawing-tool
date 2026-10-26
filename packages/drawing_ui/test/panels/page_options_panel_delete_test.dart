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

core.Page _page(String id, int index, {bool ink = false}) {
  final page = core.Page(
    id: id,
    index: index,
    size: core.PageSize.a4Portrait,
    layers: [core.Layer.empty('L')],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  return ink ? page.addStroke(_stroke('s-$id')) : page;
}

void main() {
  late ProviderContainer container;
  late ValueNotifier<bool> panelVisible;
  late List<String> trashed;
  late List<String> discarded;

  Future<void> pumpPanel(
    WidgetTester tester, {
    required int pages,
    required int pageIndex,
    int current = 0,
  }) async {
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
      pages: [for (var i = 0; i < pages; i++) _page('p$i', i, ink: i == 1)],
      currentPageIndex: current,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    container.read(documentProvider.notifier).updateDocument(doc);
    container.read(pageManagerProvider.notifier).initializeFromDocument(
          doc.pages,
          currentIndex: current,
        );
    trashed = [];
    discarded = [];
    container.read(pageTrashCallbackProvider.notifier).state = (i, p) async {
      trashed.add(p.id);
      return 'trash-${p.id}';
    };
    container.read(pageTrashDiscardCallbackProvider.notifier).state =
        (id) async => discarded.add(id);
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

  Future<void> tapDelete(WidgetTester tester) async {
    final item = find.text('Çöpe taşı');
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  List<String> ids() =>
      container.read(documentProvider).pages.map((p) => p.id).toList();

  testWidgets('delete shows an undo SnackBar and removes the page',
      (tester) async {
    await pumpPanel(tester, pages: 3, pageIndex: 1);
    await tapDelete(tester);

    expect(ids(), ['p0', 'p2']);
    expect(find.text('Sayfa silindi'), findsOneWidget);
    expect(find.text('Geri al'), findsOneWidget);
    expect(trashed, ['p1']);
    expect(discarded, isEmpty);
  });

  testWidgets('Geri al restores the same page and drops the trash entry',
      (tester) async {
    await pumpPanel(tester, pages: 3, pageIndex: 1, current: 1);
    final original = container.read(documentProvider).pages[1];
    await tapDelete(tester);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    final doc = container.read(documentProvider);
    expect(ids(), ['p0', 'p1', 'p2']);
    expect(doc.pages[1], original);
    expect(doc.pages[1].layers, original.layers);
    expect(doc.currentPageIndex, 1);
    expect(container.read(pageManagerProvider).pages.length, 3);
    expect(trashed, ['p1']);
    expect(discarded, ['trash-p1']);
  });

  testWidgets('a second delete replaces the first SnackBar', (tester) async {
    await pumpPanel(tester, pages: 3, pageIndex: 1);
    await tapDelete(tester);
    panelVisible.value = true;
    await tester.pumpAndSettle();
    await tapDelete(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sayfa silindi'), findsOneWidget);
  });

  testWidgets('the last page cannot be deleted', (tester) async {
    await pumpPanel(tester, pages: 1, pageIndex: 0);
    await tapDelete(tester);

    expect(ids(), ['p0']);
    expect(find.text('Son sayfa silinemez'), findsOneWidget);
    expect(find.text('Geri al'), findsNothing);
    expect(trashed, isEmpty);
  });
}
