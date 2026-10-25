import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/screens/page_sidebar.dart';
import 'package:drawing_ui/src/screens/page_sidebar_cells.dart';
import 'package:drawing_ui/src/screens/page_sidebar_filter_bar.dart';
import 'package:drawing_ui/src/screens/page_sidebar_widgets.dart';
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

  /// Pumps a docked sidebar over [pages]; the document and the page manager
  /// hold the same pages so bookmark toggles round-trip.
  Future<ProviderContainer> pumpSidebar(
    WidgetTester tester, {
    required List<core.Page> pages,
    int currentIndex = 0,
    ValueChanged<int>? onPageTap,
    SidebarFilter filter = SidebarFilter.allPages,
    PageSidebarVariant variant = PageSidebarVariant.docked,
  }) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        audioRecordingEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    final doc = container.read(documentProvider);
    container.read(documentProvider.notifier).updateDocument(
          doc.copyWith(pages: pages, currentPageIndex: currentIndex),
        );
    container.read(pageManagerProvider.notifier).initializeFromDocument(
          pages,
          currentIndex: currentIndex,
        );
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
                  thumbnailCache: sidebarCache(pages),
                  onPageTap: onPageTap,
                  variant: variant,
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

  Finder inItem(int index, Finder matching) => find.descendant(
        of: find.byType(PageGridItem).at(index),
        matching: matching,
      );

  Finder bookmarkIcon(int index, {bool filled = false}) => inItem(
        index,
        find.byIcon(
          filled ? ElyanotesIcons.bookmarkFilled : ElyanotesIcons.bookmark,
        ),
      );

  testWidgets('docked footprint is the card plus its left margin',
      (tester) async {
    await pumpSidebar(tester, pages: sidebarPages(3));
    expect(kPageSidebarWidth, kPageSidebarCardWidth + ChromeSpacing.sm);
    expect(tester.getSize(find.byType(PageSidebar)).width, kPageSidebarWidth);
  });

  testWidgets('filter tabs are 48dp chrome buttons', (tester) async {
    await pumpSidebar(tester, pages: sidebarPages(3));
    final tabs = find.descendant(
      of: find.byType(PageSidebarFilterBar),
      matching: find.byType(ChromeIconButton),
    );
    // Recordings tab is hidden while audio is frozen.
    expect(tabs, findsNWidgets(2));
    for (final element in tabs.evaluate()) {
      expect(element.size, const Size.square(ChromeSizes.minTouchTarget));
    }
    final selected = tester.widget<ChromeIconButton>(tabs.first);
    expect(selected.selected, isTrue);
    expect(find.byTooltip('Tüm sayfalar'), findsOneWidget);
  });

  testWidgets('bookmark shows on the selected page only, 48dp hit',
      (tester) async {
    await pumpSidebar(tester, pages: sidebarPages(3), currentIndex: 1);
    for (final filled in [false, true]) {
      expect(bookmarkIcon(0, filled: filled), findsNothing);
      expect(bookmarkIcon(2, filled: filled), findsNothing);
    }
    expect(bookmarkIcon(1), findsOneWidget);
    final hit = find.ancestor(
      of: bookmarkIcon(1),
      matching: find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == ChromeSizes.minTouchTarget,
      ),
    );
    expect(tester.getSize(hit.first), const Size.square(48));
  });

  testWidgets('a set bookmark shows on any page in accent', (tester) async {
    await pumpSidebar(
      tester,
      pages: sidebarPages(3, bookmarked: {2}),
      currentIndex: 0,
    );
    expect(bookmarkIcon(0), findsOneWidget);
    final icon = tester.widget<PhosphorIcon>(bookmarkIcon(2, filled: true));
    expect(icon.color, ChromePalette.light.accent);
  });

  testWidgets('tapping the bookmark toggles it without navigating',
      (tester) async {
    final taps = <int>[];
    final container = await pumpSidebar(
      tester,
      pages: sidebarPages(2),
      onPageTap: taps.add,
    );
    await tester.tap(bookmarkIcon(0));
    await tester.pump();
    expect(bookmarkIcon(0, filled: true), findsOneWidget);
    expect(container.read(pageManagerProvider).pages[0].isBookmarked, isTrue);
    expect(container.read(documentProvider).pages[0].isBookmarked, isTrue);
    expect(taps, isEmpty);
  });

  testWidgets('tapping a thumbnail navigates to it', (tester) async {
    final taps = <int>[];
    await pumpSidebar(tester, pages: sidebarPages(3), onPageTap: taps.add);
    await tester.tap(find.byType(PageThumbnail).at(2));
    expect(taps, [2]);
  });

  testWidgets('page options button is a 48dp target', (tester) async {
    await pumpSidebar(tester, pages: sidebarPages(2));
    final more = inItem(0, find.byType(ChromeIconButton));
    expect(more, findsOneWidget);
    expect(tester.getSize(more), const Size.square(48));
  });

  testWidgets('add-page cell closes the grid', (tester) async {
    await pumpSidebar(tester, pages: sidebarPages(2));
    expect(find.byType(AddPageCell), findsOneWidget);
    expect(find.text('Sayfa ekle'), findsOneWidget);
  });

  testWidgets('bookmarks filter without bookmarks shows the empty state',
      (tester) async {
    await pumpSidebar(
      tester,
      pages: sidebarPages(2),
      filter: SidebarFilter.bookmarked,
    );
    expect(find.byType(EmptyBookmarksState), findsOneWidget);
    expect(find.text('Henüz yer imi yok'), findsOneWidget);
    expect(find.byType(PageGridItem), findsNothing);
    expect(find.byType(AddPageCell), findsNothing);
  });

  testWidgets('bookmarks filter lists only bookmarked pages', (tester) async {
    await pumpSidebar(
      tester,
      pages: sidebarPages(4, bookmarked: {1, 3}),
      filter: SidebarFilter.bookmarked,
    );
    expect(find.byType(PageGridItem), findsNWidgets(2));
    expect(find.byType(EmptyBookmarksState), findsNothing);
  });

  testWidgets('drawer variant fills the width the host gives it',
      (tester) async {
    await pumpSidebar(
      tester,
      pages: sidebarPages(2),
      variant: PageSidebarVariant.drawer,
    );
    expect(tester.getSize(find.byType(PageSidebar)).width, 280);
  });

  testWidgets('meets the Android tap target guideline', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSidebar(tester, pages: sidebarPages(3), currentIndex: 1);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
