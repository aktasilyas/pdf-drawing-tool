import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/editor/editor.dart';

class _MockSave extends Mock implements SaveDocumentUseCase {}

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
    container = ProviderContainer(
      overrides: [saveDocumentUseCaseProvider.overrideWithValue(save)],
    );
    doc = DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a');
    container.read(hasUnsavedChangesProvider.notifier).state = true;
  });

  tearDown(() => container.dispose());

  AutoSaveNotifier notifier() => container.read(autoSaveProvider.notifier);

  test('a failed save publishes the failure and keeps unsaved changes',
      () async {
    when(() => save(any())).thenAnswer((_) async => const Left(failure));

    await notifier().saveNow(doc);

    expect(container.read(saveFailureProvider), failure);
    expect(container.read(hasUnsavedChangesProvider), isTrue);
    expect(container.read(autoSaveProvider), isFalse); // not "saving"
  });

  test('retry saves the newest document and clears the failure', () async {
    when(() => save(any())).thenAnswer((_) async => const Left(failure));
    await notifier().saveNow(doc);

    final newer = doc.copyWith(title: 'B');
    notifier().documentChanged(newer);
    when(() => save(any())).thenAnswer((_) async => const Right(null));

    await notifier().retry();

    verify(() => save(newer)).called(1);
    expect(container.read(saveFailureProvider), isNull);
    expect(container.read(hasUnsavedChangesProvider), isFalse);
  });

  test('flush after a failed autosave retries the newest document', () async {
    when(() => save(any())).thenAnswer((_) async => const Left(failure));
    await notifier().saveNow(doc);
    when(() => save(any())).thenAnswer((_) async => const Right(null));

    await notifier().flush();

    verify(() => save(doc)).called(2);
    expect(container.read(saveFailureProvider), isNull);
  });

  test('flush with nothing pending and no failure does nothing', () async {
    await notifier().flush();
    verifyNever(() => save(any()));
  });

  test('retry without any document does nothing', () async {
    await notifier().retry();
    verifyNever(() => save(any()));
  });

  test('a successful save after a failure clears the banner state', () async {
    when(() => save(any())).thenAnswer((_) async => const Left(failure));
    await notifier().saveNow(doc);
    when(() => save(any())).thenAnswer((_) async => const Right(null));

    await notifier().saveNow(doc);

    expect(container.read(saveFailureProvider), isNull);
    expect(container.read(hasUnsavedChangesProvider), isFalse);
  });
}
