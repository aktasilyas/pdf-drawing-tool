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
    documentId =
        (await fx.documents.createDocument(title: 'A', templateId: 'blank'))
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

  test('a failed undo drops its trash entries but keeps the files', () async {
    final actions = container.read(pageStructureActionsProvider);
    final image = container.read(documentProvider).pages[1];
    final change = actions.insertPages(2, [
      image.copyWith(id: 'ins-a'),
      image.copyWith(id: 'ins-b'),
    ])!;
    // Edit both inserted pages, so undo has to trash them first.
    final doc = container.read(documentProvider);
    final edited = [
      for (final p in doc.pages)
        if (p.id.startsWith('ins-'))
          p.copyWith(layers: [Layer.empty('edited')])
        else
          p,
    ];
    final current = doc.pages[doc.currentPageIndex].id;
    final notifier = container.read(documentProvider.notifier);
    notifier.updateDocument(doc.replacePages(edited, currentPageId: current));
    // The first page reaches the trash, the second fails: undo gives up
    // and discards the first entry through _discardTrash.
    final real = pageTrashCallbackFor(container.read, documentId);
    var calls = 0;
    container.read(pageTrashCallbackProvider.notifier).state =
        (index, page) async {
      calls++;
      if (calls == 1) return real(index, page);
      return null;
    };

    expect(await actions.undo(change), isFalse);

    expect(calls, 2);
    expect(await trashIds(), isEmpty);
    expect(background.existsSync(), isTrue);
  });
}
