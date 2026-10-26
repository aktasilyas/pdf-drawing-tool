import 'package:drawing_ui/drawing_ui.dart' show ToolType;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/pump_helpers.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';

/// Every pen preset of the toolbar, in toolbar group order.
const _pens = [
  ToolType.ballpointPen,
  ToolType.fountainPen,
  ToolType.pencil,
  ToolType.hardPencil,
  ToolType.gelPen,
  ToolType.dashedPen,
  ToolType.brushPen,
  ToolType.rulerPen,
  ToolType.highlighter,
  ToolType.neonHighlighter,
];

Future<EditorRobot> _openNewNotebook(WidgetTester tester, String title) async {
  await launchApp(tester);
  final library = LibraryRobot(tester);
  await library.waitForLibrary();
  await library.createNotebook(title, cover: false);
  final editor = EditorRobot(tester);
  await editor.waitForEditor();
  expect(editor.strokeIds(), isEmpty);
  return editor;
}

void main() {
  initE2E();

  testWidgets('ink: every pen preset draws a stroke; undo/redo per stroke',
      (tester) async {
    final editor = await _openNewNotebook(tester, 'E2E Kalemler');

    // One horizontal stroke per preset, each on its own row of the page.
    for (var i = 0; i < _pens.length; i++) {
      await editor.selectTool(_pens[i]);
      await editor.drawStroke(0.25 + i * 0.05);
    }
    final all = editor.strokeIds();
    expect(all, hasLength(_pens.length));

    // One undo step per stroke gesture.
    await editor.undo();
    await editor.waitStrokes(all.sublist(0, all.length - 1), 'after undo');
    await editor.redo();
    await editor.waitStrokes(all, 'after redo');
  });

  testWidgets(
      'ink: pixel eraser splits and stroke eraser removes, '
      'each undone and redone as one step', (tester) async {
    final editor = await _openNewNotebook(tester, 'E2E Silgi');

    await editor.drawStroke(0.3);
    await editor.drawStroke(0.6);
    final drawn = editor.strokeIds();
    final top = drawn[0];
    final bottom = drawn[1];

    // Pixel eraser (eraser group button in the toolbar) across the bottom
    // stroke: the stroke is replaced by its remaining pieces.
    await editor.selectTool(ToolType.pixelEraser);
    await editor.eraseAcross(0.6);
    await tester.pumpUntilTrue(
      () => !editor.strokeIds().contains(bottom),
      reason: 'pixel eraser left the stroke whole: ${editor.strokeIds()}',
    );
    final split = editor.strokeIds();
    expect(split, contains(top));
    expect(split.length, greaterThanOrEqualTo(2),
        reason: 'pieces of the erased stroke remain');

    await editor.undo();
    await editor.waitStrokes(drawn, 'pixel erase undone');
    await editor.redo();
    await editor.waitStrokes(split, 'pixel erase redone');

    // Stroke eraser across the top stroke: the whole stroke goes.
    await editor.selectTool(ToolType.strokeEraser);
    await editor.eraseAcross(0.3);
    final remaining = [...split]..remove(top);
    await editor.waitStrokes(remaining, 'stroke erase');

    await editor.undo();
    await editor.waitStrokes(split, 'stroke erase undone');
    await editor.redo();
    await editor.waitStrokes(remaining, 'stroke erase redone');
  });
}
