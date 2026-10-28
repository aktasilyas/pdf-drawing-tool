import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/features/documents/documents.dart';

import 'documents_controller_harness.dart';

void main() {
  setUpAll(registerDocumentsFallbacks);

  late DocumentsHarness h;

  setUp(() => h = DocumentsHarness());
  tearDown(() => h.dispose());

  test('emptyTrash deletes documents and pages and refreshes the trash',
      () async {
    when(() => h.repo.emptyTrash()).thenAnswer((_) async => const Right(2));
    when(() => h.pageTrash.emptyTrash())
        .thenAnswer((_) async => const Right(3));
    late bool ok;
    final rebuilt = await h.rebuiltBy(() async {
      ok = await h.controller.emptyTrash();
    });
    expect(ok, isTrue);
    verify(() => h.repo.emptyTrash()).called(1);
    verify(() => h.pageTrash.emptyTrash()).called(1);
    expect(rebuilt, {...permanentDeleteLists, ...pageTrashLists});
  });

  test('emptyTrash reports a failure and returns false', () async {
    when(() => h.repo.emptyTrash())
        .thenAnswer((_) async => const Left(failure));
    when(() => h.pageTrash.emptyTrash())
        .thenAnswer((_) async => const Right(0));
    expect(await h.controller.emptyTrash(), isFalse);
    expect(h.container.read(libraryErrorProvider), isNotNull);
  });

  test('emptyTrash reports a page trash failure and returns false', () async {
    when(() => h.repo.emptyTrash()).thenAnswer((_) async => const Right(1));
    when(() => h.pageTrash.emptyTrash())
        .thenAnswer((_) async => const Left(failure));
    expect(await h.controller.emptyTrash(), isFalse);
    expect(h.container.read(libraryErrorProvider), isNotNull);
  });
}
