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

  test('deleting a folder refreshes favorites and recent', () async {
    when(() => h.folderRepo.deleteFolder(any()))
        .thenAnswer((_) async => const Right(2));
    final rebuilt = await h.rebuiltBy(() async {
      await h.container
          .read(foldersControllerProvider.notifier)
          .deleteFolder('f1');
    });
    expect(rebuilt, containsAll(['documents', 'favorites', 'recent', 'trash']));
  });

  test('deleteFolder returns how many notes moved to the trash', () async {
    when(() => h.folderRepo.deleteFolder(any()))
        .thenAnswer((_) async => const Right(3));
    final trashed = await h.container
        .read(foldersControllerProvider.notifier)
        .deleteFolder('f1');
    expect(trashed, 3);
  });

  test('deleteFolder returns null when the repository fails', () async {
    when(() => h.folderRepo.deleteFolder(any()))
        .thenAnswer((_) async => const Left(failure));
    final trashed = await h.container
        .read(foldersControllerProvider.notifier)
        .deleteFolder('f1');
    expect(trashed, isNull);
  });
}
