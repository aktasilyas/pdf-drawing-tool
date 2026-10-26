import 'package:drawing_ui/drawing_ui.dart'
    show currentPageIndexProvider, documentProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_helpers.dart';
import 'editor_robot.dart';

/// Page object for page management in the editor: the "Daha Fazla" menu,
/// the add-page sheet and the page sidebar (a drawer on phones).
///
/// Sidebar cells are found by their semantics labels ("Sayfa 2",
/// "Yer imi ekle"). The phone drawer stays mounted off-screen while closed,
/// so every sidebar finder is restricted to hit-testable widgets.
class PagesRobot {
  PagesRobot(this.tester) : _editor = EditorRobot(tester);

  final WidgetTester tester;
  final EditorRobot _editor;

  static final _pageLabel = RegExp(r'^Sayfa \d+$');

  Finder _semantics(bool Function(String label) test) => find
      .byWidgetPredicate(
        (w) => w is Semantics && test(w.properties.label ?? ''),
      )
      .hitTestable();

  /// Sidebar cell of the 1-based page [number].
  Finder pageCell(int number) => _semantics((l) => l == 'Sayfa $number');

  /// All page cells currently visible in the sidebar.
  Finder get pageCells => _semantics(_pageLabel.hasMatch);

  List<String> pageIds() =>
      [for (final p in _editor.read(documentProvider).pages) p.id];

  int get currentIndex => _editor.read(currentPageIndexProvider);

  bool isBookmarked(String pageId) => _editor
      .read(documentProvider)
      .pages
      .firstWhere((p) => p.id == pageId)
      .isBookmarked;

  Future<void> _tapVisible(Finder finder) async {
    await tester.pumpUntilFound(finder);
    await tester.ensureVisible(finder.first);
    await tester.pumpFor(const Duration(milliseconds: 300));
    await tester.tapAndWait(finder.first.hitTestable());
  }

  /// "Daha Fazla" > "Sayfa Ekle" > blank template. The new page goes after
  /// the current one and becomes current.
  Future<void> addPage() async {
    final before = pageIds().length;
    await tester.tapAndWait(find.byTooltip('Daha Fazla').hitTestable());
    await _tapVisible(find.text('Sayfa Ekle'));
    await _tapVisible(find.text('Boş'));
    await tester.pumpUntilTrue(
      () => pageIds().length == before + 1,
      reason: 'page not added (${pageIds().length} pages)',
    );
    await tester.pumpFor(const Duration(milliseconds: 500));
  }

  /// Opens the page sidebar ("Sayfa Paneli", shown from two pages on).
  /// No-op when the sidebar is already open.
  Future<void> openSidebar() async {
    if (pageCells.evaluate().isNotEmpty) return;
    await tester.tapAndWait(find.byTooltip('Sayfa Paneli').hitTestable());
    await tester.pumpUntilFound(pageCells);
    await tester.pumpFor(const Duration(milliseconds: 300));
  }

  /// Long-press drags the cell of page [from] onto the cell of page [to].
  Future<void> dragPage({required int from, required int to}) async {
    final start = tester.getCenter(pageCell(from).first);
    final end = tester.getCenter(pageCell(to).first);
    final gesture = await tester.startGesture(start);
    // Past the 500 ms long-press timeout, so the cell starts dragging.
    await tester.pumpFor(const Duration(milliseconds: 800));
    const steps = 10;
    for (var i = 1; i <= steps; i++) {
      await gesture.moveTo(Offset.lerp(start, end, i / steps)!);
      await tester.pump(const Duration(milliseconds: 32));
    }
    await tester.pumpFor(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpFor(const Duration(milliseconds: 600));
  }

  /// Cell "..." of page [number] > "Çöpe taşı". The delete needs no
  /// confirmation and shows a "Sayfa silindi" SnackBar with "Geri al".
  Future<void> deletePage(int number) async {
    final more = find.byTooltip('Sayfa seçenekleri').hitTestable();
    await tester.pumpUntilFound(more);
    await tester.tapAndWait(more.at(number - 1));
    await _tapVisible(find.text('Çöpe taşı'));
    await tester.pumpUntilFound(find.text('Sayfa silindi'));
  }

  /// "Geri al" on the delete SnackBar.
  Future<void> undoDelete() async {
    await tester.tapAndWait(find.widgetWithText(SnackBarAction, 'Geri al'));
  }

  /// Bookmark toggle on the current page's cell (the only cell that shows
  /// an empty toggle).
  Future<void> bookmarkCurrentPage() async {
    await tester.tapAndWait(_semantics((l) => l == 'Yer imi ekle'));
  }

  /// Sidebar filter tabs.
  Future<void> showBookmarks() async {
    await tester.tapAndWait(find.byTooltip('Yer imleri').hitTestable());
  }

  Future<void> showAllPages() async {
    await tester.tapAndWait(find.byTooltip('Tüm sayfalar').hitTestable());
  }
}
