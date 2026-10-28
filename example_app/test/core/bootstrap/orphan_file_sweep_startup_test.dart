import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/bootstrap/orphan_file_sweep_startup.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

class _MockSweep extends Mock implements SweepOrphanedFilesUseCase {}

void main() {
  final now = DateTime(2026, 7, 1);
  late _MockSweep sweep;

  setUpAll(() => registerFallbackValue(now));
  setUp(() => sweep = _MockSweep());

  test('waits for the first frame before sweeping', () async {
    when(() => sweep(any())).thenAnswer((_) async => const Right(1));
    final frame = Completer<void>();

    final done = sweepOrphanedFilesAfterFirstFrame(
      sweep,
      firstFrame: frame.future,
      delay: Duration.zero,
      clock: () => now,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verifyNever(() => sweep(any()));

    frame.complete();
    await done;
    verify(() => sweep(now)).called(1);
  });

  test('swallows a Left result', () async {
    when(() => sweep(any()))
        .thenAnswer((_) async => const Left(CacheFailure('x')));

    await sweepOrphanedFilesAfterFirstFrame(
      sweep,
      firstFrame: Future.value(),
      delay: Duration.zero,
    );
  });

  test('swallows a throwing use case', () async {
    when(() => sweep(any())).thenThrow(StateError('boom'));

    await sweepOrphanedFilesAfterFirstFrame(
      sweep,
      firstFrame: Future.value(),
      delay: Duration.zero,
    );
  });
}
