import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart' show documentProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart'
    show DocumentRepository, documentRepositoryProvider;
import 'package:example_app/features/editor/editor.dart';

class _MockSave extends Mock implements SaveDocumentUseCase {}

class _MockRepository extends Mock implements DocumentRepository {}

Stroke _stroke() =>
    Stroke.create(style: StrokeStyle.pen()).addPoint(DrawingPoint(x: 1, y: 1));

/// Moving the open notebook to the trash from the editor saves it first and
/// never trashes it while its edits could not be saved (#480).
void main() {
  late _MockSave save;
  late _MockRepository repo;
  late ProviderContainer container;
  late DrawingDocument doc;

  const failure = CacheFailure('disk full');
  const ok = Right<Failure, void>(null);

  setUpAll(() {
    registerFallbackValue(DrawingDocument.emptyMultiPage('fallback'));
  });

  setUp(() {
    save = _MockSave();
    repo = _MockRepository();
    when(() => save(any())).thenAnswer((_) async => ok);
    when(() => repo.moveToTrash(any())).thenAnswer((_) async => ok);
    container = ProviderContainer(
      overrides: [
        saveDocumentUseCaseProvider.overrideWithValue(save),
        documentRepositoryProvider.overrideWithValue(repo),
      ],
    );
    final empty = DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a');
    doc = empty.addPage(Page.create(index: 1));
    startEditorSession(container.read, doc);
  });

  tearDown(() => container.dispose());

  /// Draws a stroke the way the editor's document listener reports it.
  DrawingDocument draw() {
    final drawn = doc.addStrokeToActiveLayer(_stroke());
    container.read(documentProvider.notifier).updateDocument(drawn);
    onEditorDocumentChanged(container.read, doc, drawn);
    return drawn;
  }

  testWidgets('a failed save does not trash and keeps the Retry banner state',
      (tester) async {
    when(() => save(any())).thenAnswer((_) async => const Left(failure));
    draw();

    final trashed = await moveOpenDocumentToTrash(container.read, 'doc_a');

    expect(trashed, isFalse);
    verifyNever(() => repo.moveToTrash(any()));
    expect(container.read(saveFailureProvider), failure);
    expect(container.read(hasUnsavedChangesProvider), isTrue);
  });

  testWidgets('a successful save is written before the trash', (tester) async {
    final drawn = draw();

    final trashed = await moveOpenDocumentToTrash(container.read, 'doc_a');

    expect(trashed, isTrue);
    verifyInOrder([
      () => save(drawn),
      () => repo.moveToTrash('doc_a'),
    ]);
    expect(container.read(saveFailureProvider), isNull);
  });

  testWidgets('Retry after a failure, then delete: the latest edits are saved',
      (tester) async {
    when(() => save(any())).thenAnswer((_) async => const Left(failure));
    final drawn = draw();
    expect(await moveOpenDocumentToTrash(container.read, 'doc_a'), isFalse);

    when(() => save(any())).thenAnswer((_) async => ok);
    await container.read(autoSaveProvider.notifier).retry();
    expect(container.read(saveFailureProvider), isNull);

    expect(await moveOpenDocumentToTrash(container.read, 'doc_a'), isTrue);
    verify(() => save(drawn)).called(2);
    verify(() => repo.moveToTrash('doc_a')).called(1);
  });

  testWidgets('a failed trash reports false after the save', (tester) async {
    when(() => repo.moveToTrash(any()))
        .thenAnswer((_) async => const Left(failure));
    final drawn = draw();

    expect(await moveOpenDocumentToTrash(container.read, 'doc_a'), isFalse);
    verify(() => save(drawn)).called(1);
    verify(() => repo.moveToTrash('doc_a')).called(1);
  });
}
