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
        .thenAnswer((_) async => const Right(null));
    final rebuilt = await h.rebuiltBy(() async {
      await h.container
          .read(foldersControllerProvider.notifier)
          .deleteFolder('f1');
    });
    expect(rebuilt, containsAll(['documents', 'favorites', 'recent', 'trash']));
  });
}
