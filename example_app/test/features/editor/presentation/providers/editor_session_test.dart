import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/editor/editor.dart';

Stroke _stroke() {
  final stroke = Stroke.create(style: StrokeStyle.pen());
  return stroke.addPoint(DrawingPoint(x: 10, y: 10));
}

void main() {
  late ProviderContainer container;
  late DrawingDocument docA;
  late DrawingDocument docB;

  setUp(() {
    container = ProviderContainer();
    docA = DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a');
    docB = DrawingDocument.emptyMultiPage('B').copyWith(id: 'doc_b');
  });

  tearDown(() => container.dispose());

  HistoryState history() => container.read(historyManagerProvider);

  /// Leaves the canvas fitted to a wide page, then zoomed and panned away,
  /// like a user would.
  void zoomAndPan() {
    container.read(canvasTransformProvider.notifier)
      ..initializeForPage(
        viewportSize: const Size(800, 1200),
        pageSize: const Size(1190, 842),
      )
      ..setZoom(4)
      ..setOffset(const Offset(-900, -1200));
    expect(container.read(canvasTransformProvider).baselineZoom, isNot(1.0));
  }

  test('opening a document empties the undo history', () {
    startEditorSession(container.read, docA);
    container.read(historyManagerProvider.notifier).addStroke(_stroke());
    expect(history().canUndo, isTrue);

    startEditorSession(container.read, docB);

    expect(history().canUndo, isFalse);
    expect(history().canRedo, isFalse);
    expect(container.read(documentProvider).id, 'doc_b');
    expect(container.read(currentDocumentProvider)?.id, 'doc_b');
  });

  test('undo after switching documents leaves the new document unchanged', () {
    startEditorSession(container.read, docA);
    container.read(historyManagerProvider.notifier).addStroke(_stroke());
    startEditorSession(container.read, docB);

    container.read(historyManagerProvider.notifier).undo();

    final doc = container.read(documentProvider);
    expect(doc.id, 'doc_b');
    expect(doc.strokeCount, 0);
    expect(container.read(pageManagerProvider).pages, docB.pages);
  });

  test('redo history of the old document is dropped too', () {
    startEditorSession(container.read, docA);
    container.read(historyManagerProvider.notifier).addStroke(_stroke());
    container.read(historyManagerProvider.notifier).undo();
    expect(history().canRedo, isTrue);

    startEditorSession(container.read, docB);

    expect(history().canRedo, isFalse);
  });

  test('closing the editor empties the undo history', () {
    startEditorSession(container.read, docA);
    container.read(historyManagerProvider.notifier).addStroke(_stroke());

    endEditorSession(container.read);

    expect(history().canUndo, isFalse);
    expect(history().undoCount, 0);
  });

  test('closing the editor drops the Locate PDF handler', () {
    startEditorSession(container.read, docA);
    container.read(pdfSourceRelinkProvider.notifier).state = (_) async => true;

    endEditorSession(container.read);

    expect(container.read(pdfSourceRelinkProvider), isNull);
  });

  group('closeEditorSession', () {
    test('resets history, document state and pdf state', () {
      startEditorSession(container.read, docA);
      container.read(historyManagerProvider.notifier).addStroke(_stroke());
      container.read(hasUnsavedChangesProvider.notifier).state = true;
      container.read(visiblePdfPageProvider.notifier).state = 3;
      container.read(totalPdfPagesProvider.notifier).state = 9;

      closeEditorSession(container.read, container.invalidate);

      expect(history().canUndo, isFalse);
      expect(container.read(documentProvider).id, isNot('doc_a'));
      expect(container.read(hasUnsavedChangesProvider), isFalse);
      expect(container.read(saveFailureProvider), isNull);
      expect(container.read(pageTrashCallbackProvider), isNull);
      expect(container.read(pageTrashDiscardCallbackProvider), isNull);
      expect(container.read(visiblePdfPageProvider), isNull);
      expect(container.read(totalPdfPagesProvider), 0);
    });

    test('reopening the same document starts a fresh session', () {
      startEditorSession(container.read, docA);
      container.read(historyManagerProvider.notifier).addStroke(_stroke());

      closeEditorSession(container.read, container.invalidate);
      expect(container.read(documentProvider).id, isNot(docA.id));

      startEditorSession(container.read, docA);
      expect(history().canUndo, isFalse);
    });

    test('resets the canvas transform to the default view (#474)', () {
      startEditorSession(container.read, docA);
      zoomAndPan();

      closeEditorSession(container.read, container.invalidate);

      expect(container.read(canvasTransformProvider), const CanvasTransform());
    });
  });

  group('canvas transform per document (#474)', () {
    final whiteboard = DrawingDocument.emptyMultiPage(
      'W',
      documentType: DocumentType.whiteboard,
    ).copyWith(id: 'whiteboard');

    test('a whiteboard opened after a zoomed document starts at 100%', () {
      startEditorSession(container.read, docA);
      zoomAndPan();

      startEditorSession(container.read, whiteboard);

      final transform = container.read(canvasTransformProvider);
      expect(whiteboard.canvasMode.isInfinite, isTrue);
      expect(transform.zoom, 1.0);
      expect(transform.baselineZoom, 1.0);
      expect(transform.offset, Offset.zero);
      expect(container.read(zoomPercentageProvider), '100%');
    });

    test('a notebook is still fitted to its page after the reset', () {
      startEditorSession(container.read, whiteboard);
      zoomAndPan();

      startEditorSession(container.read, docA);
      container.read(canvasTransformProvider.notifier).initializeForPage(
            viewportSize: const Size(800, 1200),
            pageSize: const Size(595, 842),
          );

      final transform = container.read(canvasTransformProvider);
      expect(transform.zoom, transform.baselineZoom);
      expect(transform.zoom, isNot(4));
      expect(container.read(zoomPercentageProvider), '100%');
    });
  });
}
