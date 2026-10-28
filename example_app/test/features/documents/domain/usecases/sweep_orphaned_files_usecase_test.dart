import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

class _MockRepo extends Mock implements DocumentRepository {}

class _MockSchedule extends Mock implements MaintenanceSchedule {}

void main() {
  final now = DateTime(2026, 7, 2, 12);
  late _MockRepo repo;
  late _MockSchedule schedule;
  late SweepOrphanedFilesUseCase useCase;

  setUpAll(() => registerFallbackValue(now));

  setUp(() {
    repo = _MockRepo();
    schedule = _MockSchedule();
    useCase = SweepOrphanedFilesUseCase(repo, schedule);
    when(() => schedule.setLastOrphanSweep(any())).thenAnswer((_) async {});
    when(() => repo.sweepOrphanedFiles(olderThan: any(named: 'olderThan')))
        .thenAnswer((_) async => const Right(2));
  });

  test('runs when never run, with a 10 minute grace, and stores now', () async {
    when(() => schedule.lastOrphanSweep()).thenAnswer((_) async => null);

    expect(await useCase(now), const Right<Failure, int>(2));

    verify(
      () => repo.sweepOrphanedFiles(
        olderThan: now.subtract(const Duration(minutes: 10)),
      ),
    ).called(1);
    verify(() => schedule.setLastOrphanSweep(now)).called(1);
  });

  test('is throttled within 24 hours', () async {
    when(() => schedule.lastOrphanSweep())
        .thenAnswer((_) async => now.subtract(const Duration(hours: 23)));

    expect(await useCase(now), const Right<Failure, int>(0));

    verifyNever(
      () => repo.sweepOrphanedFiles(olderThan: any(named: 'olderThan')),
    );
    verifyNever(() => schedule.setLastOrphanSweep(any()));
  });

  test('runs again after 24 hours', () async {
    when(() => schedule.lastOrphanSweep())
        .thenAnswer((_) async => now.subtract(const Duration(hours: 24)));

    await useCase(now);

    verify(() => schedule.setLastOrphanSweep(now)).called(1);
  });

  test('runs when the stored time is in the future', () async {
    when(() => schedule.lastOrphanSweep())
        .thenAnswer((_) async => now.add(const Duration(days: 3)));

    await useCase(now);

    verify(() => schedule.setLastOrphanSweep(now)).called(1);
  });

  test('does not store the time when the sweep fails', () async {
    when(() => schedule.lastOrphanSweep()).thenAnswer((_) async => null);
    when(() => repo.sweepOrphanedFiles(olderThan: any(named: 'olderThan')))
        .thenAnswer((_) async => const Left(CacheFailure('x')));

    expect((await useCase(now)).isLeft(), isTrue);

    verifyNever(() => schedule.setLastOrphanSweep(any()));
  });
}
