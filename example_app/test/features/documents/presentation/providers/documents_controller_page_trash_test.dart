import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'documents_controller_harness.dart';

void main() {
  setUpAll(registerDocumentsFallbacks);

  late DocumentsHarness h;

  setUp(() => h = DocumentsHarness());
  tearDown(() => h.dispose());

  test('movePageToTrash stores the page and refreshes page trash', () async {
    when(() => h.pageTrash.movePageToTrash(
          documentId: any(named: 'documentId'),
          documentTitle: any(named: 'documentTitle'),
          pageIndex: any(named: 'pageIndex'),
          pageData: any(named: 'pageData'),
        )).thenAnswer((_) async {});
    final rebuilt = await h.rebuiltBy(() async {
      await h.controller.movePageToTrash(
        documentId: 'doc-1',
        documentTitle: 'Notes',
        pageIndex: 2,
        pageData: {'id': 'p1'},
      );
    });
    verify(() => h.pageTrash.movePageToTrash(
          documentId: 'doc-1',
          documentTitle: 'Notes',
          pageIndex: 2,
          pageData: {'id': 'p1'},
        )).called(1);
    expect(rebuilt, pageTrashLists);
  });

  group('restorePageFromTrash', () {
    for (final restored in [true, false]) {
      test('returns $restored and refreshes page trash + documents', () async {
        when(() => h.pageTrash.restorePageFromTrash('t1'))
            .thenAnswer((_) async => restored);
        late bool result;
        final rebuilt = await h.rebuiltBy(() async {
          result = await h.controller.restorePageFromTrash('t1');
        });
        expect(result, restored);
        expect(rebuilt, {...pageTrashLists, 'documents'});
      });
    }
  });

  test('permanentlyDeletePage removes it and refreshes page trash', () async {
    when(() => h.pageTrash.permanentlyDeletePage('t1'))
        .thenAnswer((_) async {});
    final rebuilt = await h.rebuiltBy(() async {
      await h.controller.permanentlyDeletePage('t1');
    });
    verify(() => h.pageTrash.permanentlyDeletePage('t1')).called(1);
    expect(rebuilt, pageTrashLists);
  });

  test('trashedPageDocumentExists forwards to the repository', () async {
    when(() => h.pageTrash.documentExists('doc-1'))
        .thenAnswer((_) async => true);
    late bool exists;
    final rebuilt = await h.rebuiltBy(() async {
      exists = await h.controller.trashedPageDocumentExists('doc-1');
    });
    expect(exists, isTrue);
    expect(rebuilt, isEmpty);
  });
}
