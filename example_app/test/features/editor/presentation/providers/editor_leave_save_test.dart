import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart'
    show documentProvider, textToolProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/editor/editor.dart';

class _MockSave extends Mock implements SaveDocumentUseCase {}

Stroke _stroke() =>
    Stroke.create(style: StrokeStyle.pen()).addPoint(DrawingPoint(x: 1, y: 1));

/// Leaving a notebook without edits must not rewrite it (#467): no save, so
/// its modified date and place in a date-sorted library stay as they were.
void main() {
  late _MockSave save;
  late ProviderContainer container;
  late DrawingDocument doc;

  const failure = CacheFailure('disk full');

  setUpAll(() {
    registerFallbackValue(DrawingDocument.emptyMultiPage('fallback'));
  });

  setUp(() {
    save = _MockSave();
    when(() => save(any())).thenAnswer((_) async => const Right(null));
    container = ProviderContainer(
      overrides: [saveDocumentUseCaseProvider.overrideWithValue(save)],
    );
    final empty = DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a');
    doc = empty.addPage(Page.create(index: 1));
    startEditorSession(container.read, doc);
  });

  tearDown(() => container.dispose());

  /// What the editor's document listener sees for an edit from [from].
  void change(DrawingDocument from, DrawingDocument to) {
    container.read(documentProvider.notifier).updateDocument(to);
    onEditorDocumentChanged(container.read, from, to);
  }

  group('isViewOnlyChange', () {
    test('turning the page is view state', () {
      expect(isViewOnlyChange(doc, doc.setCurrentPage(1)), isTrue);
    });

    test('a stroke, a title or a new page is content', () {
      final drawn = doc.addStrokeToActiveLayer(_stroke());
      final added = doc.addPage(Page.create(index: 2));
      expect(isViewOnlyChange(doc, drawn), isFalse);
      expect(isViewOnlyChange(doc, doc.updateTitle('B')), isFalse);
      expect(isViewOnlyChange(doc, added), isFalse);
    });

    test('another document is never view-only', () {
      expect(isViewOnlyChange(doc, doc.copyWith(id: 'doc_b')), isFalse);
    });
  });

  testWidgets('open → back without changes saves nothing', (tester) async {
    expect(await saveBeforeLeavingEditor(container.read), isTrue);
    await tester.pump(const Duration(seconds: 5));
    verifyNever(() => save(any()));
  });

  testWidgets('only turning pages saves nothing and keeps the date',
      (tester) async {
    final turned = doc.setCurrentPage(1);
    change(doc, turned);
    expect(turned.updatedAt, doc.updatedAt);
    expect(container.read(hasUnsavedChangesProvider), isFalse);

    await tester.pump(const Duration(seconds: 5));
    expect(await saveBeforeLeavingEditor(container.read), isTrue);
    verifyNever(() => save(any()));
  });

  testWidgets('a stroke is saved on leave', (tester) async {
    final drawn = doc.addStrokeToActiveLayer(_stroke());
    change(doc, drawn);
    expect(container.read(hasUnsavedChangesProvider), isTrue);

    expect(await saveBeforeLeavingEditor(container.read), isTrue);
    verify(() => save(drawn)).called(1);
  });

  testWidgets('a page turn after an edit rides along with the pending save',
      (tester) async {
    final drawn = doc.addStrokeToActiveLayer(_stroke());
    change(doc, drawn);
    final turned = drawn.setCurrentPage(1);
    change(drawn, turned);

    expect(await saveBeforeLeavingEditor(container.read), isTrue);
    verify(() => save(turned)).called(1);
    verifyNoMoreInteractions(save);
  });

  testWidgets('a save running at leave is awaited', (tester) async {
    final running = Completer<Either<Failure, void>>();
    when(() => save(any())).thenAnswer((_) => running.future);
    change(doc, doc.addStrokeToActiveLayer(_stroke()));
    await tester.pump(AutoSaveNotifier.debounce);
    verify(() => save(any())).called(1);

    var left = false;
    unawaited(saveBeforeLeavingEditor(container.read).then((ok) => left = ok));
    await tester.pump();
    expect(left, isFalse);

    running.complete(const Right(null));
    await tester.pump();
    await tester.pump();
    expect(left, isTrue);
    verifyNoMoreInteractions(save);
  });

  testWidgets('a running save that fails keeps the editor open',
      (tester) async {
    final running = Completer<Either<Failure, void>>();
    when(() => save(any())).thenAnswer((_) => running.future);
    change(doc, doc.addStrokeToActiveLayer(_stroke()));
    await tester.pump(AutoSaveNotifier.debounce);

    when(() => save(any())).thenAnswer((_) async => const Left(failure));
    final leaving = saveBeforeLeavingEditor(container.read);
    running.complete(const Left(failure));

    expect(await leaving, isFalse);
    expect(container.read(saveFailureProvider), failure);
  });

  group('text being typed (#489)', () {
    void type(String value) {
      final notifier = container.read(textToolProvider.notifier);
      notifier.startNewText(10, 20, pageId: doc.pages.first.id, layerIndex: 0);
      final active = container.read(textToolProvider).activeText!;
      notifier.updateText(active.copyWith(text: value));
    }

    testWidgets('is committed and saved on leave', (tester) async {
      type('Hello');

      expect(await saveBeforeLeavingEditor(container.read), isTrue);

      final saved =
          verify(() => save(captureAny())).captured.single as DrawingDocument;
      expect(
        saved.pages.first.layers.first.texts.map((t) => t.text),
        ['Hello'],
      );
      expect(container.read(textToolProvider).isEditing, isFalse);
    });

    testWidgets('an empty text box saves nothing', (tester) async {
      type('  ');

      expect(await saveBeforeLeavingEditor(container.read), isTrue);

      verifyNever(() => save(any()));
      expect(container.read(textToolProvider).isEditing, isFalse);
    });
  });
}
