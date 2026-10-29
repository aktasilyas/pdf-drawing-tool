import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
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
}
