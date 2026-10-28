import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/core/di/injection.dart';
import 'package:example_app/features/documents/documents.dart';

class _MockDocs extends Mock implements DocumentRepository {}

class _MockPages extends Mock implements PageTrashRepository {}

void main() {
  final now = DateTime(2026, 7, 1);

  setUpAll(() => registerFallbackValue(now));

  test('purges with the injected clock and swallows failures', () async {
    final docs = _MockDocs();
    final pages = _MockPages();
    when(() => docs.purgeExpiredTrash(now: any(named: 'now')))
        .thenAnswer((_) async => const Right(1));
    when(() => pages.purgeExpired(now: any(named: 'now')))
        .thenAnswer((_) async => const Right(2));

    await purgeExpiredTrashOnStartup(
      PurgeExpiredTrashUseCase(docs, pages),
      clock: () => now,
    );
    verify(() => docs.purgeExpiredTrash(now: now)).called(1);
    verify(() => pages.purgeExpired(now: now)).called(1);

    when(() => docs.purgeExpiredTrash(now: any(named: 'now')))
        .thenAnswer((_) async => const Left(CacheFailure('x')));
    when(() => pages.purgeExpired(now: any(named: 'now')))
        .thenThrow(StateError('boom'));
    await purgeExpiredTrashOnStartup(
      PurgeExpiredTrashUseCase(docs, pages),
      clock: () => now,
    );
  });
}
