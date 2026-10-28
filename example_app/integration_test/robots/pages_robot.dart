import 'package:drawing_core/drawing_core.dart' show TemplateRegistry;
import 'package:drawing_ui/drawing_ui.dart'
    show currentPageIndexProvider, documentProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/l10n.dart';
import '../helpers/pump_helpers.dart';
import 'editor_robot.dart';

/// Page object for page management in the editor: the "more" menu, the
/// add-page sheet and the page sidebar (a drawer on phones).
///
/// Sidebar cells are found by their localized semantics labels (page number,
/// "add bookmark"). The phone drawer stays mounted off-screen while closed,
/// so every sidebar finder is restricted to hit-testable widgets.
class PagesRobot {
  PagesRobot(this.tester) : _editor = EditorRobot(tester);

  final WidgetTester tester;
  final EditorRobot _editor;

  Finder _semantics(bool Function(String label) test) => find
      .byWidgetPredicate(
        (w) => w is Semantics && test(w.properties.label ?? ''),
      )
      .hitTestable();

  /// Sidebar cell of the 1-based page [number].
  Finder pageCell(int number) {
    final label = tester.drawingStrings.pages.pageNumber(number);
    return _semantics((l) => l == label);
  }

  /// All page cells currently visible in the sidebar.
  Finder get pageCells {
    // The localized label of page 0 with the digit swapped for a pattern.
    final template = tester.drawingStrings.pages.pageNumber(0);
    final pattern = RegExp.escape(template).replaceFirst('0', r'\d+');
    return _semantics(RegExp('^$pattern\$').hasMatch);
  }

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

  /// "More" > "Add page" > blank template. The new page goes after the
  /// current one and becomes current.
  Future<void> addPage() async {
    final s = tester.drawingStrings;
    final before = pageIds().length;
    await tester.tapAndWait(find.byTooltip(s.toolbar.more).hitTestable());
    await _tapVisible(find.text(s.toolbar.addPage));
    await _tapVisible(
      find.text(s.templates.templateName(TemplateRegistry.blank)),
    );
    await tester.pumpUntilTrue(
      () => pageIds().length == before + 1,
      reason: 'page not added (${pageIds().length} pages)',
    );
    await tester.pumpFor(const Duration(milliseconds: 500));
  }

  /// Opens the page sidebar (the "pages" button, shown from two pages on).
  /// No-op when the sidebar is already open.
  Future<void> openSidebar() async {
    if (pageCells.evaluate().isNotEmpty) return;
    await tester.tapAndWait(
      find.byTooltip(tester.drawingStrings.toolbar.pages).hitTestable(),
    );
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

  /// Cell "..." of page [number] > "Move to trash". The delete needs no
  /// confirmation and shows a "page deleted" SnackBar with "Undo".
  Future<void> deletePage(int number) async {
    final s = tester.drawingStrings;
    final more = find.byTooltip(s.pageList.pageOptions).hitTestable();
    await tester.pumpUntilFound(more);
    await tester.tapAndWait(more.at(number - 1));
    await _tapVisible(find.text(s.pages.movePageToTrash));
    await tester.pumpUntilFound(find.text(s.pages.pageDeleted));
  }

  /// "Undo" on the delete SnackBar.
  Future<void> undoDelete() async {
    await tester.tapAndWait(
      find.widgetWithText(SnackBarAction, tester.drawingStrings.toolbar.undo),
    );
  }

  /// Bookmark toggle on the current page's cell (the only cell that shows
  /// an empty toggle).
  Future<void> bookmarkCurrentPage() async {
    final label = tester.drawingStrings.pageList.addBookmark;
    await tester.tapAndWait(_semantics((l) => l == label));
  }

  /// Sidebar filter tabs.
  Future<void> showBookmarks() async {
    final label = tester.drawingStrings.pageList.filterBookmarks;
    await tester.tapAndWait(find.byTooltip(label).hitTestable());
  }

  Future<void> showAllPages() async {
    final label = tester.drawingStrings.pageList.filterAllPages;
    await tester.tapAndWait(find.byTooltip(label).hitTestable());
  }
}
