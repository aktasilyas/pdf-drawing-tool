// Text being edited is committed to the page it was started on, and a page
// change ends editing (#462).
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DrawingCanvasState state;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DrawingCanvas())),
      ),
    );
    final finder = find.byType(DrawingCanvas);
    state = tester.state<DrawingCanvasState>(finder);
    container = ProviderScope.containerOf(tester.element(finder));

    var doc = core.DrawingDocument.emptyMultiPage('Notes');
    doc = doc.addPage(core.Page.create(index: 1));
    doc = doc.addPage(core.Page.create(index: 2));
    container.read(documentProvider.notifier).updateDocument(doc);
    container.read(pageManagerProvider.notifier).initializeFromDocument(
          doc.pages,
          currentIndex: 0,
        );
    container.read(currentToolProvider.notifier).selectTool(ToolType.text);
    await tester.pump();
  }

  /// Navigates the way the editor does: PageManager first, then the
  /// document's currentPageIndex is synced (drawing_screen_viewport_sync).
  Future<void> goToPage(WidgetTester tester, int index) async {
    container.read(pageManagerProvider.notifier).goToPage(index);
    final doc = container.read(documentProvider);
    container
        .read(documentProvider.notifier)
        .updateDocument(doc.setCurrentPage(index));
    await tester.pump();
  }

  List<core.TextElement> textsOnPage(int index) =>
      container.read(documentProvider).pages[index].layers.first.texts;

  void tap(Offset at) {
    state.handlePointerDown(PointerDownEvent(position: at));
  }

  void type(String value) {
    final notifier = container.read(textToolProvider.notifier);
    final active = container.read(textToolProvider).activeText!;
    notifier.updateText(active.copyWith(text: value));
  }

  testWidgets('new text started on page 1 stays there after a page change',
      (tester) async {
    await pump(tester);
    tap(const Offset(100, 100));
    type('Hello');

    container.read(pageManagerProvider.notifier).goToPage(2);
    final doc = container.read(documentProvider);
    container
        .read(documentProvider.notifier)
        .updateDocument(doc.setCurrentPage(2));
    state.finishTextEditing();
    await tester.pump();

    expect(textsOnPage(0).single.text, 'Hello');
    expect(textsOnPage(2), isEmpty);
    expect(container.read(currentPageIndexProvider), 2);
    expect(container.read(documentProvider).currentPageIndex, 2);
  });

  testWidgets('switching pages while editing commits and closes the overlay',
      (tester) async {
    await pump(tester);
    tap(const Offset(100, 100));
    type('Hello');
    expect(container.read(textToolProvider).isEditing, isTrue);

    await goToPage(tester, 2);

    expect(container.read(textToolProvider).isEditing, isFalse);
    expect(textsOnPage(0).single.text, 'Hello');
    expect(textsOnPage(2), isEmpty);
    expect(container.read(currentPageIndexProvider), 2);
  });

  testWidgets('page-1 edit survives a page switch; undo restores it',
      (tester) async {
    await pump(tester);
    tap(const Offset(100, 100));
    type('Hello');
    state.finishTextEditing();
    // Committing a new text switches to the selection tool.
    container.read(currentToolProvider.notifier).selectTool(ToolType.text);
    container.read(selectionProvider.notifier).clearSelection();
    final undoBefore = container.read(historyManagerProvider).undoCount;

    tap(const Offset(105, 105));
    expect(container.read(textToolProvider).isNewText, isFalse);
    type('World');
    await goToPage(tester, 1);

    expect(container.read(textToolProvider).isEditing, isFalse);
    expect(textsOnPage(0).single.text, 'World');
    expect(textsOnPage(1), isEmpty);
    expect(container.read(historyManagerProvider).undoCount, undoBefore + 1);

    container.read(historyManagerProvider.notifier).undo();
    expect(textsOnPage(0).single.text, 'Hello');
  });

  testWidgets('same-page editing is unchanged and selects the new text',
      (tester) async {
    await pump(tester);
    tap(const Offset(100, 100));
    type('Hello');
    state.finishTextEditing();

    expect(textsOnPage(0).single.text, 'Hello');
    final selected = container.read(selectionProvider)?.selectedTextIds;
    expect(selected, [textsOnPage(0).single.id]);
  });
}
