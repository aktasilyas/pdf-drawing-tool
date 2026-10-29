import 'package:drawing_ui/drawing_ui.dart'
    show
        DrawingCanvas,
        DrawingScreen,
        ToolType,
        ToolTypeLabel,
        activeLayerStrokesProvider,
        canvasTransformProvider,
        currentPageProvider,
        currentToolProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/l10n.dart';
import '../helpers/pump_helpers.dart';

/// Toolbar groups: one button per group, the variants live in its panel.
const _highlighters = {ToolType.highlighter, ToolType.neonHighlighter};
const _erasers = {
  ToolType.pixelEraser,
  ToolType.strokeEraser,
  ToolType.lassoEraser,
};

/// Page object for the editor screen (drawing_ui toolbar chrome).
///
/// Gestures go through the real canvas; assertions read the editor's
/// Riverpod state (stroke ids, current tool), never pixels.
class EditorRobot {
  EditorRobot(this.tester);

  final WidgetTester tester;

  /// Home button of the phone, medium and full toolbar layouts.
  Finder get _homeButton =>
      find.byTooltip(tester.drawingStrings.toolbar.home);

  Finder get _canvas => find.byType(DrawingCanvas).first;

  ProviderContainer get _container => ProviderScope.containerOf(
        tester.element(find.byType(DrawingScreen)),
        listen: false,
      );

  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  /// Waits until the editor chrome is on screen.
  Future<void> waitForEditor() async {
    await tester.pumpUntilFound(
      _homeButton,
      timeout: const Duration(seconds: 30),
    );
    await tester.pumpUntilFound(_canvas);
    // Let the limited-mode canvas fit the page (post-frame transform).
    await tester.pumpFor(const Duration(milliseconds: 500));
  }

  /// Taps the home button; the editor saves and routes to `/documents`.
  Future<void> goHome() async {
    await tester.tapAndWait(_homeButton);
  }

  /// Ids of the strokes on the current page's active layer, in order.
  List<String> strokeIds() =>
      [for (final s in read(activeLayerStrokesProvider)) s.id];

  ToolType get currentTool => read(currentToolProvider);

  /// Selects [tool]. A group head (pen, highlighter, eraser) is tapped in
  /// the toolbar by its tooltip; a variant inside the already selected group
  /// is picked through the tool provider, because the pen-type picker sheet
  /// is covered by widget tests and its live previews make it slow here.
  /// Eraser types are switched with [selectEraserType].
  Future<void> selectTool(ToolType tool) async {
    final current = currentTool;
    if (current == tool) return;
    assert(
      !(_erasers.contains(current) && _erasers.contains(tool)),
      'use selectEraserType to switch between eraser types',
    );
    final button =
        find.byTooltip(tool.label(tester.drawingStrings)).hitTestable();
    if (button.evaluate().isNotEmpty && !_sameGroup(current, tool)) {
      await tester.tap(button.first);
    } else {
      read(currentToolProvider.notifier).selectTool(tool);
    }
    await tester.pumpUntilTrue(
      () => currentTool == tool,
      reason: 'tool $tool not selected (still $currentTool)',
    );
    await tester.pumpFor(const Duration(milliseconds: 300));
  }

  /// Switches the eraser type the way a user does: tap the selected eraser
  /// button to open its panel, pick the type, close the sheet. The panel
  /// also sets the eraser mode the canvas erases with, which the tool
  /// provider alone does not.
  Future<void> selectEraserType(ToolType type) async {
    assert(_erasers.contains(type), '$type is not an eraser');
    if (!_erasers.contains(currentTool)) {
      await selectTool(ToolType.pixelEraser);
    }
    if (currentTool == type) return;
    await tester.tapAndWait(
      find.byTooltip(currentTool.label(tester.drawingStrings)).hitTestable(),
    );
    final option =
        find.byKey(ValueKey('eraser-type-${type.name}')).hitTestable();
    await tester.tapAndWait(option);
    await tester.pumpUntilTrue(
      () => currentTool == type,
      reason: 'eraser $type not selected (still $currentTool)',
    );
    await tester.tapAndWait(
      find.byTooltip(tester.drawingStrings.panels.close).hitTestable(),
    );
    // The toolbar button now carries the same tooltip, so wait for the
    // panel's own button (keyed by type) to leave the tree.
    await tester.pumpUntilGone(
      find.byKey(ValueKey('eraser-type-${type.name}')),
    );
  }

  bool _sameGroup(ToolType a, ToolType b) {
    if (_highlighters.contains(a)) return _highlighters.contains(b);
    if (_erasers.contains(a)) return _erasers.contains(b);
    final aPen = a.isPenTool && !_highlighters.contains(a);
    final bPen = b.isPenTool && !_highlighters.contains(b);
    return aPen && bPen;
  }

  /// Global screen position of a point given as a fraction of the current
  /// page (0..1 on both axes), through the live canvas transform.
  Offset pagePoint(double fx, double fy) {
    final page = read(currentPageProvider);
    final transform = read(canvasTransformProvider);
    final local = transform.canvasToScreen(
      Offset(page.size.width * fx, page.size.height * fy),
    );
    return tester.getTopLeft(_canvas) + local;
  }

  /// One-finger drag from [from] to [to] (page fractions) in small steps,
  /// like a pen stroke or an eraser swipe.
  Future<void> swipe(Offset from, Offset to, {int steps = 12}) async {
    final start = pagePoint(from.dx, from.dy);
    final end = pagePoint(to.dx, to.dy);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 1; i <= steps; i++) {
      await gesture.moveTo(Offset.lerp(start, end, i / steps)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpFor(const Duration(milliseconds: 300));
  }

  /// Draws a horizontal stroke at page height [fy] with the current tool and
  /// waits until it is committed.
  Future<void> drawStroke(double fy) async {
    final before = strokeIds().length;
    await swipe(Offset(0.25, fy), Offset(0.75, fy), steps: 24);
    await tester.pumpUntilTrue(
      () => strokeIds().length == before + 1,
      reason: 'stroke with $currentTool at y=$fy not committed '
          '(${strokeIds().length} strokes, expected ${before + 1})',
    );
  }

  /// Vertical swipe through the middle of the page around height [fy],
  /// crossing a stroke drawn there with [drawStroke].
  Future<void> eraseAcross(double fy) =>
      swipe(Offset(0.5, fy - 0.05), Offset(0.5, fy + 0.05));

  /// Renames the open notebook through the editor's rename dialog: the
  /// title button's menu when the title is shown, else "More" (phone).
  Future<void> renameDocument(String to) async {
    final s = tester.drawingStrings;
    final titleButton = find.byTooltip(s.pages.documentOptions).hitTestable();
    await tester.tapAndWait(
      titleButton.evaluate().isNotEmpty
          ? titleButton.first
          : find.byTooltip(s.toolbar.more).hitTestable(),
    );
    final item = find.text(s.pages.rename).hitTestable();
    await tester.pumpUntilFound(item);
    await tester.tapAndWait(item.first);
    final dialog = find.byType(AlertDialog);
    await tester.pumpUntilFound(dialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      to,
    );
    await tester.pumpFor(const Duration(milliseconds: 300));
    final save = find.text(tester.l10n.commonSave);
    await tester.tapAndWait(find.descendant(of: dialog, matching: save));
    await tester.pumpUntilGone(dialog);
  }

  Future<void> undo() async {
    await tester.tapAndWait(
      find.byTooltip(tester.drawingStrings.toolbar.undo).hitTestable(),
    );
  }

  Future<void> redo() async {
    await tester.tapAndWait(
      find.byTooltip(tester.drawingStrings.toolbar.redo).hitTestable(),
    );
  }

  /// Waits until the page holds exactly the stroke ids in [expected]
  /// (order ignored: undo may restore a stroke at the end of the list).
  Future<void> waitStrokes(List<String> expected, String reason) =>
      tester.pumpUntilTrue(
        () {
          final ids = strokeIds();
          return ids.length == expected.length &&
              ids.toSet().containsAll(expected);
        },
        reason: '$reason: strokes ${strokeIds()}, expected $expected',
      );
}
