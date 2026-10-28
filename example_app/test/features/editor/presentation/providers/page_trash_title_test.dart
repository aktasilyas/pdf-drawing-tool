import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/domain/repositories/page_trash_repository.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/editor/editor.dart';

class MockPageTrashRepository extends Mock implements PageTrashRepository {}

class MockDocumentRepository extends Mock implements DocumentRepository {}

void main() {
  test('a page trashed after an in-editor rename records the new title',
      () async {
    final trashRepo = MockPageTrashRepository();
    when(
      () => trashRepo.movePageToTrash(
        documentId: any(named: 'documentId'),
        documentTitle: any(named: 'documentTitle'),
        pageIndex: any(named: 'pageIndex'),
        pageData: any(named: 'pageData'),
      ),
    ).thenAnswer((_) async => const Right('trash-1'));
    final container = ProviderContainer(overrides: [
      pageTrashRepositoryProvider.overrideWithValue(trashRepo),
      documentRepositoryProvider.overrideWithValue(MockDocumentRepository()),
    ]);
    addTearDown(container.dispose);

    final doc = DrawingDocument.emptyMultiPage('Old name');
    startEditorSession(container.read, doc);
    final trash = pageTrashCallbackFor(container.read, doc.id);

    container.read(documentProvider.notifier).updateTitle('New name');
    final id = await trash(0, doc.pages.first);

    expect(id, 'trash-1');
    verify(
      () => trashRepo.movePageToTrash(
        documentId: doc.id,
        documentTitle: 'New name',
        pageIndex: 0,
        pageData: any(named: 'pageData'),
      ),
    ).called(1);
  });
}
