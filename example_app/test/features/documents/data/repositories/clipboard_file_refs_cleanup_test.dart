import 'dart:io';

import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:example_app/core/core.dart' show ClipboardFileRefs;
import 'package:example_app/features/documents/documents.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/library_fixture.dart';

/// Files a clipboard still references survive document delete and page-trash
/// purge, and are collected once the clipboard no longer holds them.
void main() {
  late LibraryFixture fx;
  late Directory dir;
  late ClipboardFileRefs clipboard;
  var held = <String>{};

  setUp(() {
    held = {};
    clipboard = ClipboardFileRefs()..paths = () => held;
    dir = Directory.systemTemp.createTempSync('elya_clip_');
    Directory('${dir.path}/pdfs').createSync();
    Directory('${dir.path}/elyanotes_images').createSync();
    fx = LibraryFixture(null, PdfPathResolver(dir.path), clipboard);
  });
  tearDown(() async {
    await fx.close();
    dir.deleteSync(recursive: true);
  });

  File file(String key) => File('${dir.path}/$key')..writeAsStringSync('x');

  Future<DocumentInfo> create(String title) async =>
      (await fx.documents.createDocument(title: title, templateId: 'blank'))
          .getOrElse(() => throw StateError('create failed'));

  Map<String, dynamic> page(String pdf, String image) => {
        'id': 'p',
        'index': 0,
        'background': {'type': 'pdf', 'pdfFilePath': pdf},
        'layers': [
          {
            'images': [
              {'id': 'i', 'filePath': image},
            ],
          },
        ],
      };

  test('deleteDocument keeps the PDF and image of the copied page', () async {
    final pdf = file('pdfs/a.pdf');
    final img = file('elyanotes_images/a.png');
    final a = await create('A');
    await fx.documents.saveDocumentContent(
      id: a.id,
      content: {
        'pages': [page('pdfs/a.pdf', 'elyanotes_images/a.png')],
      },
    );
    held = {'pdfs/a.pdf', 'elyanotes_images/a.png'};

    await fx.documents.permanentlyDelete(a.id);

    expect(pdf.existsSync(), isTrue);
    expect(img.existsSync(), isTrue);
  });

  test('a copied selection image survives, others are deleted', () async {
    final kept = file('elyanotes_images/sel.png');
    final gone = file('elyanotes_images/other.png');
    final a = await create('A');
    await fx.documents.saveDocumentContent(
      id: a.id,
      content: {
        'pages': [page('pdfs/none.pdf', 'elyanotes_images/sel.png')],
      },
    );
    await fx.documentDs.deleteUnreferencedFiles(['elyanotes_images/other.png']);
    held = {'elyanotes_images/sel.png'};

    await fx.documents.permanentlyDelete(a.id);

    expect(kept.existsSync(), isTrue);
    expect(gone.existsSync(), isFalse);
  });

  test('page-trash purge keeps clipboard files', () async {
    final pdf = file('pdfs/t.pdf');
    final a = await create('A');
    await fx.documents.saveDocumentContent(id: a.id, content: {
      'pages': [
        {'id': 'keep', 'index': 0},
      ],
    });
    final id = (await fx.pageTrash.movePageToTrash(
      documentId: a.id,
      documentTitle: 'A',
      pageIndex: 1,
      pageData: page('pdfs/t.pdf', 'elyanotes_images/none.png'),
    ))
        .getOrElse(() => throw StateError('trash failed'));
    held = {'pdfs/t.pdf'};

    await fx.pageTrash.permanentlyDeletePage(id);

    expect(pdf.existsSync(), isTrue);
  });

  test('files are deleted once the clipboard no longer holds them', () async {
    final pdf = file('pdfs/later.pdf');
    held = {'pdfs/later.pdf'};
    await fx.documentDs.deleteUnreferencedFiles(['pdfs/later.pdf']);
    expect(pdf.existsSync(), isTrue);

    held = {};
    await fx.documentDs.deleteUnreferencedFiles(['pdfs/later.pdf']);
    expect(pdf.existsSync(), isFalse);
  });
}
