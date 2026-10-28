import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/library_fixture.dart';

/// Image files (image pages and image elements) are freed together with the
/// content that references them, against real Drift.
void main() {
  late LibraryFixture fx;
  late Directory dir;
  final recent = DateTime(2026, 6, 30);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('elya_trash_img_');
    Directory('${dir.path}/elyanotes_images').createSync();
    fx = LibraryFixture(null, PdfPathResolver(dir.path));
  });
  tearDown(() async {
    await fx.close();
    dir.deleteSync(recursive: true);
  });

  File imageFile(String name) =>
      File('${dir.path}/elyanotes_images/$name')..writeAsStringSync('x');

  Future<DocumentInfo> create(String title) async =>
      (await fx.documents.createDocument(title: title, templateId: 'blank'))
          .getOrElse(() => throw StateError('create failed'));

  Map<String, dynamic> imagePage(String name) => {
        'id': 'p-$name',
        'index': 0,
        'background': {
          'type': 'pdf',
          'pdfPageIndex': 1,
          'imageFilePath': 'elyanotes_images/$name',
        },
      };

  Map<String, dynamic> elementPage(String name) => {
        'id': 'e-$name',
        'index': 0,
        'background': {'type': 'blank'},
        'layers': [
          {
            'images': [
              {'id': 'img', 'filePath': 'elyanotes_images/$name'},
            ],
          },
        ],
      };

  Map<String, dynamic> content(List<Map<String, dynamic>> pages) =>
      {'pages': pages};

  Future<void> save(String id, List<Map<String, dynamic>> pages) =>
      fx.documents.saveDocumentContent(id: id, content: content(pages));

  Future<void> trashDoc(String id) async {
    final doc = await fx.documentDs.getDocument(id);
    await fx.documentDs.updateDocument(
      doc.copyWith(isInTrash: true, deletedAt: recent),
    );
  }

  test('permanent delete removes the image background and element files',
      () async {
    final bg = imageFile('bg.png');
    final el = imageFile('el.png');
    final a = await create('A');
    await save(a.id, [imagePage('bg.png'), elementPage('el.png')]);

    await fx.documents.permanentlyDelete(a.id);

    expect(bg.existsSync(), isFalse);
    expect(el.existsSync(), isFalse);
  });

  test('a file another document still references survives', () async {
    final shared = imageFile('shared.png');
    final own = imageFile('own.png');
    final a = await create('A');
    final b = await create('B');
    await save(a.id, [imagePage('shared.png'), elementPage('own.png')]);
    await save(b.id, [elementPage('shared.png')]);

    await fx.documents.permanentlyDelete(a.id);
    expect(shared.existsSync(), isTrue);
    expect(own.existsSync(), isFalse);

    await fx.documents.permanentlyDelete(b.id);
    expect(shared.existsSync(), isFalse);
  });

  test('a file used by a trashed page of another document survives',
      () async {
    final file = imageFile('t.png');
    final a = await create('A');
    final b = await create('B');
    await save(a.id, [imagePage('t.png')]);
    await fx.trashDs.addTrashedPage(TrashedPageModel(
      id: 'tb',
      pageId: 'p',
      sourceDocumentId: b.id,
      sourceDocumentTitle: 'B',
      originalPageIndex: 0,
      deletedAt: recent,
      pageData: imagePage('t.png'),
    ));

    await fx.documents.permanentlyDelete(a.id);

    expect(file.existsSync(), isTrue);
  });

  test('empty trash removes the files of trashed documents', () async {
    final file = imageFile('e.png');
    final a = await create('A');
    await save(a.id, [imagePage('e.png')]);
    await trashDoc(a.id);

    await fx.documents.emptyTrash();

    expect(file.existsSync(), isFalse);
  });

  test('removing a trashed image page deletes its file', () async {
    final file = imageFile('page.png');
    final a = await create('A');
    await save(a.id, [
      {'id': 'keep', 'index': 0},
    ]);
    final id = (await fx.pageTrash.movePageToTrash(
      documentId: a.id,
      documentTitle: 'A',
      pageIndex: 1,
      pageData: imagePage('page.png'),
    ))
        .getOrElse(() => throw StateError('trash failed'));
    expect(file.existsSync(), isTrue);

    await fx.pageTrash.permanentlyDeletePage(id);

    expect(file.existsSync(), isFalse);
  });

  test('an image element pointing outside the app is never deleted',
      () async {
    final outside = File('${dir.path}/user_photo.png')..writeAsStringSync('x');
    final a = await create('A');
    await save(a.id, [
      {
        'id': 'o',
        'index': 0,
        'background': {'type': 'blank'},
        'layers': [
          {
            'images': [
              {'id': 'img', 'filePath': outside.path},
            ],
          },
        ],
      },
    ]);

    await fx.documents.permanentlyDelete(a.id);

    expect(outside.existsSync(), isTrue);
  });
}
