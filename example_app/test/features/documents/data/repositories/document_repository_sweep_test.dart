import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/pass_through_runner.dart';

class _MockDatasource extends Mock implements DocumentLocalDatasource {}

class _MockFolders extends Mock implements FolderLocalDatasource {}

void main() {
  final cutoff = DateTime(2026, 7, 1);
  late _MockDatasource datasource;
  late DocumentRepositoryImpl repository;

  setUp(() {
    datasource = _MockDatasource();
    repository = DocumentRepositoryImpl(
      datasource,
      _MockFolders(),
      PassThroughRunner(),
    );
  });

  test('returns the datasource count', () async {
    when(() => datasource.sweepOrphanedFiles(olderThan: cutoff))
        .thenAnswer((_) async => 3);

    expect(
      await repository.sweepOrphanedFiles(olderThan: cutoff),
      const Right<Failure, int>(3),
    );
  });

  test('returns Left when the datasource throws', () async {
    when(() => datasource.sweepOrphanedFiles(olderThan: cutoff))
        .thenThrow(const CacheException('boom'));

    final result = await repository.sweepOrphanedFiles(olderThan: cutoff);

    expect(result.isLeft(), isTrue);
  });

  test('returns Left when the datasource throws something else', () async {
    when(() => datasource.sweepOrphanedFiles(olderThan: cutoff))
        .thenThrow(StateError('boom'));

    final result = await repository.sweepOrphanedFiles(olderThan: cutoff);

    expect(result.isLeft(), isTrue);
  });
}
