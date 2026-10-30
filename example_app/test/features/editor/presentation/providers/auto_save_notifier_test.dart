import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/editor/editor.dart';

class _MockSave extends Mock implements SaveDocumentUseCase {}

class _MockThumbnails extends Mock implements LibraryThumbnailWriter {}

void main() {
  late _MockSave save;
  late _MockThumbnails thumbnails;
  late ProviderContainer container;
  late DrawingDocument doc;

  setUpAll(() {
    registerFallbackValue(DrawingDocument.emptyMultiPage('fallback'));
  });

  setUp(() {
    save = _MockSave();
    thumbnails = _MockThumbnails();
    when(() => save(any())).thenAnswer((_) async => const Right(null));
    container = ProviderContainer(
      overrides: [
        saveDocumentUseCaseProvider.overrideWithValue(save),
        libraryThumbnailWriterProvider.overrideWithValue(thumbnails),
      ],
    );
    doc = DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a');
  });

  tearDown(() => container.dispose());

  AutoSaveNotifier notifier() => container.read(autoSaveProvider.notifier);

  testWidgets('saves once after the debounce', (tester) async {
    notifier().documentChanged(doc);
    expect(notifier().hasPendingSave, isTrue);

    await tester.pump(const Duration(seconds: 2));
    verifyNever(() => save(any()));

    await tester.pump(const Duration(seconds: 1));
    verify(() => save(doc)).called(1);
    expect(notifier().hasPendingSave, isFalse);
  });

  testWidgets('a new change restarts the debounce', (tester) async {
    final next = doc.copyWith(title: 'B');
    notifier().documentChanged(doc);
    await tester.pump(const Duration(seconds: 2));
    notifier().documentChanged(next);
    await tester.pump(const Duration(seconds: 2));
    verifyNever(() => save(any()));

    await tester.pump(const Duration(seconds: 1));
    verify(() => save(next)).called(1);
    verifyNever(() => save(doc));
  });

  testWidgets('saveNow saves at once and cancels the timer', (tester) async {
    notifier().documentChanged(doc);
    await notifier().saveNow(doc);
    verify(() => save(doc)).called(1);

    await tester.pump(const Duration(seconds: 5));
    verifyNoMoreInteractions(save);
  });

  testWidgets('flush saves a pending change immediately', (tester) async {
    notifier().documentChanged(doc);
    await notifier().flush();
    verify(() => save(doc)).called(1);
    expect(notifier().hasPendingSave, isFalse);

    await tester.pump(const Duration(seconds: 5));
    verifyNoMoreInteractions(save);
  });

  testWidgets('flush without a pending change does nothing', (tester) async {
    await notifier().flush();
    verifyNever(() => save(any()));
  });

  testWidgets('a finished save clears the unsaved flag', (tester) async {
    container.read(hasUnsavedChangesProvider.notifier).state = true;
    notifier().documentChanged(doc);
    await notifier().flush();
    expect(container.read(hasUnsavedChangesProvider), isFalse);
  });

  testWidgets('a change during a save keeps the unsaved flag', (tester) async {
    container.read(hasUnsavedChangesProvider.notifier).state = true;
    final saving = notifier().saveNow(doc);
    notifier().documentChanged(doc.copyWith(title: 'B'));
    await saving;
    expect(container.read(hasUnsavedChangesProvider), isTrue);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('closing the editor session cancels a pending autosave',
      (tester) async {
    startEditorSession(container.read, doc);
    notifier().documentChanged(doc);
    expect(notifier().hasPendingSave, isTrue);

    closeEditorSession(container.read, container.invalidate);
    await tester.pump(const Duration(seconds: 5));

    verifyNever(() => save(any()));
  });

  testWidgets('a successful save asks for a library thumbnail', (tester) async {
    await notifier().saveNow(doc);
    verify(() => thumbnails.request(doc)).called(1);
  });

  testWidgets('a failed save does not ask for a thumbnail', (tester) async {
    when(() => save(any()))
        .thenAnswer((_) async => const Left(CacheFailure('disk full')));
    await notifier().saveNow(doc);
    verifyNever(() => thumbnails.request(any()));
  });
}
