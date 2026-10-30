import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/screens/page_sidebar.dart';
import 'package:drawing_ui/src/screens/page_sidebar_reorder.dart';
import 'package:drawing_ui/src/screens/page_sidebar_widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../golden/helpers/chrome_theme.dart';
import '../golden/helpers/sidebar_fixture.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> pumpSidebar(
    WidgetTester tester, {
    required PageSidebarVariant variant,
    SidebarFilter filter = SidebarFilter.allPages,
    List<core.Page>? pages,
    ValueChanged<int>? onPageTap,
  }) async {
    final all = pages ?? sidebarPages(4);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        audioRecordingEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    final doc = container.read(documentProvider);
    container.read(documentProvider.notifier).updateDocument(
          doc.copyWith(pages: all, currentPageIndex: 1),
        );
    container
        .read(pageManagerProvider.notifier)
        .initializeFromDocument(all, currentIndex: 1);
    container.read(sidebarFilterProvider.notifier).state = filter;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: chromeTheme(Brightness.light),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: variant == PageSidebarVariant.docked
                    ? kPageSidebarWidth
                    : 280,
                height: 700,
                child: PageSidebar(
                  thumbnailCache: sidebarCache(all),
                  variant: variant,
                  onPageTap: onPageTap,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  Future<void> drag(WidgetTester tester, int from, int to) async {
    final start = tester.getCenter(find.byType(PageGridItem).at(from));
    final end = tester.getCenter(find.byType(PageGridItem).at(to));
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    for (var i = 1; i <= 5; i++) {
      await gesture.moveTo(Offset.lerp(start, end, i / 5)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final variant in PageSidebarVariant.values) {
    testWidgets(
        'long-press drag of page 3 onto page 1 reorders (${variant.name})',
        (tester) async {
      final container = await pumpSidebar(tester, variant: variant);

      await drag(tester, 2, 0);

      final ids = [
        for (final p in container.read(documentProvider).pages) p.id
      ];
      expect(ids, ['page_2', 'page_0', 'page_1', 'page_3']);
      final manager = container.read(pageManagerProvider);
      expect([for (final p in manager.pages) p.id], ids);
      expect(manager.pages[manager.currentIndex].id, 'page_1');
      final doc = container.read(documentProvider);
      expect(doc.pages[doc.currentPageIndex].id, 'page_1');
      for (var i = 0; i < 4; i++) {
        expect(find.text('${i + 1}'), findsWidgets);
      }
    });
  }

  testWidgets('no draggable under the bookmarks filter', (tester) async {
    await pumpSidebar(
      tester,
      variant: PageSidebarVariant.docked,
      filter: SidebarFilter.bookmarked,
      pages: sidebarPages(4, bookmarked: {0, 2}),
    );
    expect(find.byType(ReorderablePageCell), findsNothing);
  });

  testWidgets('tap still navigates', (tester) async {
    final taps = <int>[];
    await pumpSidebar(
      tester,
      variant: PageSidebarVariant.docked,
      onPageTap: taps.add,
    );
    await tester.tap(find.byType(PageGridItem).at(3));
    await tester.pump();
    expect(taps, [3]);
  });

  testWidgets('cover cell is not draggable and not a drop target',
      (tester) async {
    final pages = sidebarPages(4);
    pages[0] = pages[0].copyWith(isCover: true);
    final container = await pumpSidebar(
      tester,
      variant: PageSidebarVariant.docked,
      pages: pages,
    );

    // 3 reorderable cells, none for the cover.
    expect(find.byType(ReorderablePageCell), findsNWidgets(3));
    expect(
      find.descendant(
        of: find.byType(PageGridItem).first,
        matching: find.byType(LongPressDraggable<int>),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.byType(PageGridItem).first,
        matching: find.byType(DragTarget<int>),
      ),
      findsNothing,
    );

    await drag(tester, 2, 0);

    final ids = [for (final p in container.read(documentProvider).pages) p.id];
    expect(ids.first, 'page_0');
  });
}
