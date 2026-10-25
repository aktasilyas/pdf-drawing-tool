// Characterization test for the DrawingCanvas element tree (issue #55,
// docs/plans/55-split-drawing-canvas.md). Each scenario dumps the widget type
// of every element under DrawingCanvas and compares it with a fixture in
// test/canvas/fixtures. Regenerate (only on known-good code) with
// UPDATE_CANVAS_TREE=1.
import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _limited = CanvasMode(isInfinite: false);

String _dump(Element root) {
  final buffer = StringBuffer();
  void visit(Element element, int depth) {
    buffer.writeln('${'  ' * depth}${element.widget.runtimeType}');
    element.visitChildElements((child) => visit(child, depth + 1));
  }

  visit(root, 0);
  return buffer.toString();
}

void main() {
  late ProviderContainer container;

  Future<void> pumpCanvas(
    WidgetTester tester, {
    CanvasMode? mode,
    void Function(ProviderContainer c)? setup,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    container = ProviderContainer();
    addTearDown(container.dispose);
    setup?.call(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: DrawingCanvas(canvasMode: mode)),
        ),
      ),
    );
    await tester.pump();
  }

  void expectTree(WidgetTester tester, String scenario) {
    final element = tester.element(find.byType(DrawingCanvas));
    final actual = _dump(element);
    final file = File('test/canvas/fixtures/drawing_canvas_tree_$scenario.txt');
    if (Platform.environment['UPDATE_CANVAS_TREE'] == '1') {
      file.writeAsStringSync(actual);
      return;
    }
    expect(actual, file.readAsStringSync());
  }

  testWidgets('infinite mode', (tester) async {
    await pumpCanvas(tester);
    expectTree(tester, 'infinite');
  });

  testWidgets('limited mode, blank page', (tester) async {
    await pumpCanvas(tester, mode: _limited);
    expectTree(tester, 'limited_blank');
  });

  testWidgets('limited mode, PDF placeholder', (tester) async {
    await pumpCanvas(
      tester,
      mode: _limited,
      setup: (c) =>
          c.read(pageManagerProvider.notifier).initializeFromDocument([
        Page.create(
          index: 0,
          background: const PageBackground(type: BackgroundType.pdf),
        ),
      ]),
    );
    expectTree(tester, 'limited_pdf_placeholder');
  });

  testWidgets('sticker placement', (tester) async {
    await pumpCanvas(tester);
    container.read(stickerPlacementProvider.notifier).selectEmoji('x');
    await tester.pump();
    expectTree(tester, 'sticker_placement');
  });

  testWidgets('image placement', (tester) async {
    await pumpCanvas(tester);
    container.read(imagePlacementProvider.notifier).selectImagePath('a.png');
    await tester.pump();
    expectTree(tester, 'image_placement');
  });

  testWidgets('eraser tool', (tester) async {
    await pumpCanvas(tester);
    container
        .read(currentToolProvider.notifier)
        .selectTool(ToolType.pixelEraser);
    await tester.pump();
    expectTree(tester, 'eraser');
  });

  testWidgets('sticky note menu and handles', (tester) async {
    await pumpCanvas(tester);
    container
        .read(currentToolProvider.notifier)
        .selectTool(ToolType.stickyNote);
    container
        .read(stickyNotePlacementProvider.notifier)
        .selectNote(StickyNote.create(x: 10, y: 10));
    container.read(stickyNotePlacementProvider.notifier).showContextMenu();
    await tester.pump();
    expectTree(tester, 'sticky_note');
  });

  testWidgets('text editing', (tester) async {
    await pumpCanvas(tester);
    container.read(textToolProvider.notifier).startNewText(20, 20);
    await tester.pump();
    expectTree(tester, 'text_editing');
  });

  testWidgets('selection with menu', (tester) async {
    await pumpCanvas(tester);
    container.read(selectionProvider.notifier).setSelection(
          Selection.create(
            type: SelectionType.rectangle,
            selectedStrokeIds: const ['s1'],
            bounds:
                const BoundingBox(left: 10, top: 10, right: 100, bottom: 100),
          ),
        );
    container.read(selectionUiProvider.notifier).showContextMenu();
    await tester.pump();
    expectTree(tester, 'selection_menu');
  });
}
