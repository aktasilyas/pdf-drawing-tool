import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/editor/editor.dart';

import '../../../../helpers/library_fixture.dart';

/// Undoing a page delete in the editor must never delete the page's files,
/// even after autosave stored the content without the page (#460).
void main() {
  late Directory dir;
  late LibraryFixture fx;
  late ProviderContainer container;
  late File background;
  late String documentId;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('elya_undo_delete_');
    Directory('${dir.path}/elyanotes_images').createSync();
    background = File('${dir.path}/elyanotes_images/bg.png')
      ..writeAsStringSync('x');
    fx = LibraryFixture(null, PdfPathResolver(dir.path));
    container = ProviderContainer(overrides: [
      pageTrashRepositoryProvider.overrideWithValue(fx.pageTrash),
      documentRepositoryProvider.overrideWithValue(fx.documents),
    ]);
    documentId = (await fx.documents
            .createDocument(title: 'A', templateId: 'blank'))
        .getOrElse(() => throw StateError('create failed'))
        .id;
    // Autosave already ran: the stored content no longer has the image page.
    await fx.documents.saveDocumentContent(
      id: documentId,
      content: {
        'pages': [
          {'id': 'keep', 'index': 0},
        ],
      },
    );

    final base = DrawingDocument.emptyMultiPage('A').copyWith(id: documentId);
    final imagePage = base.pages.first.copyWith(
      id: 'image-page',
      index: 1,
      background: const PageBackground(
        type: BackgroundType.pdf,
        pdfPageIndex: 1,
        imageFilePath: 'elyanotes_images/bg.png',
      ),
    );
    startEditorSession(
      container.read,
      base.copyWith(pages: [...base.pages, imagePage]),
    );
    container.read(pageTrashCallbackProvider.notifier).state =
        pageTrashCallbackFor(container.read, documentId);
    container.read(pageTrashDiscardCallbackProvider.notifier).state =
        pageTrashDiscardCallbackFor(container.read);
  });

  tearDown(() async {
    container.dispose();
    await fx.close();
    dir.deleteSync(recursive: true);
  });

  Future<List<String>> trashIds() async => [
        for (final p in await fx.trashDs.getTrashedPages()) p.id,
      ];

  test('restorePage keeps the files and drops the trash row', () async {
    final actions = container.read(pageStructureActionsProvider);
    final deleted = await actions.deletePage(1);
    expect(deleted?.trashId, isNotNull);
    expect(await trashIds(), [deleted!.trashId]);

    await actions.restorePage(deleted);

    expect(container.read(documentProvider).pages, hasLength(2));
    expect(await trashIds(), isEmpty);
    expect(background.existsSync(), isTrue);
  });

  test('a discard from the undo path keeps the files', () async {
    final id = await pageTrashCallbackFor(container.read, documentId)(
      1,
      container.read(documentProvider).pages[1],
    );
    expect(id, isNotNull);

    // undo() -> _discardTrash calls the same discard callback.
    await container.read(pageTrashDiscardCallbackProvider)!(id!);

    expect(await trashIds(), isEmpty);
    expect(background.existsSync(), isTrue);
  });
}
