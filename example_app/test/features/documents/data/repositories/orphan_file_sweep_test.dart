import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/library_fixture.dart';

/// The orphaned-file sweep against real Drift and a real temp directory.
void main() {
  late LibraryFixture fx;
  late Directory dir;
  // Files just written count as old for this cutoff...
  late DateTime cutoff;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('elya_sweep_');
    Directory('${dir.path}/pdfs').createSync();
    Directory('${dir.path}/elyanotes_images').createSync();
    fx = LibraryFixture(null, PdfPathResolver(dir.path));
    cutoff = DateTime.now().add(const Duration(hours: 1));
  });
  tearDown(() async {
    await fx.close();
    dir.deleteSync(recursive: true);
  });

  File file(String relative) =>
      File('${dir.path}/$relative')..writeAsStringSync('x');

  Future<int> sweep([DateTime? olderThan]) async {
    final result = await fx.documents.sweepOrphanedFiles(
      olderThan: olderThan ?? cutoff,
    );
    return result.getOrElse(() => throw StateError('sweep failed'));
  }

  Future<DocumentInfo> create(String title) async =>
      (await fx.documents.createDocument(title: title, templateId: 'blank'))
          .getOrElse(() => throw StateError('create failed'));

  Future<void> saveRaw(String id, String data) =>
      fx.db.into(fx.db.documentContents).insertOnConflictUpdate(
            DocumentContentsCompanion(
              documentId: Value(id),
              data: Value(data),
              updatedAt: Value(DateTime.now()),
            ),
          );

  Map<String, dynamic> elementPage(String path) => {
        'id': 'p',
        'index': 0,
        'layers': [
          {
            'images': [
              {'id': 'img', 'filePath': path},
            ],
          },
        ],
      };

  test('deletes unreferenced images and PDFs and returns the count', () async {
    final img = file('elyanotes_images/orphan.png');
    final pdf = file('pdfs/orphan.pdf');

    expect(await sweep(), 2);

    expect(img.existsSync(), isFalse);
    expect(pdf.existsSync(), isFalse);
  });

  test('keeps files referenced by document content', () async {
    final img = file('elyanotes_images/kept.png');
    final pdf = file('pdfs/kept.pdf');
    final orphan = file('elyanotes_images/orphan.png');
    final doc = await create('A');
    await saveRaw(
      doc.id,
      json.encode({
        'pages': [
          elementPage('elyanotes_images/kept.png'),
          {
            'id': 'q',
            'index': 1,
            'background': {'type': 'pdf', 'pdfFilePath': 'pdfs/kept.pdf'},
          },
        ],
      }),
    );

    expect(await sweep(), 1);

    expect(img.existsSync(), isTrue);
    expect(pdf.existsSync(), isTrue);
    expect(orphan.existsSync(), isFalse);
  });

  test('keeps files referenced by a trashed page', () async {
    final img = file('elyanotes_images/trashed.png');
    await fx.db.into(fx.db.trashedPages).insert(
          TrashedPagesCompanion.insert(
            id: 't1',
            pageId: 'p',
            sourceDocumentId: 'gone',
            sourceDocumentTitle: 'Gone',
            originalPageIndex: 0,
            deletedAt: DateTime.now(),
            pageData: json.encode(elementPage('elyanotes_images/trashed.png')),
          ),
        );

    expect(await sweep(), 0);
    expect(img.existsSync(), isTrue);
  });

  test('keeps a file used as a document thumbnail', () async {
    final img = file('elyanotes_images/thumb.png');
    final doc = await create('A');
    await fx.documents.updateDocument(
      id: doc.id,
      thumbnailPath: 'elyanotes_images/thumb.png',
    );

    expect(await sweep(), 0);
    expect(img.existsSync(), isTrue);
  });

  test('keeps files referenced by legacy absolute and Windows paths', () async {
    final unix = file('elyanotes_images/unix.png');
    final win = file('pdfs/win.pdf');
    final doc = await create('A');
    await saveRaw(
      doc.id,
      json.encode({
        'pages': [
          elementPage('/old/device/files/elyanotes_images/unix.png'),
          elementPage(r'C:\Users\me\Documents\pdfs\win.pdf'),
        ],
      }),
    );

    expect(await sweep(), 0);
    expect(unix.existsSync(), isTrue);
    expect(win.existsSync(), isTrue);
  });

  test('keeps recently changed files', () async {
    final recent = file('elyanotes_images/recent.png')
      ..setLastModifiedSync(DateTime.now().add(const Duration(hours: 2)));

    expect(await sweep(), 0);
    expect(recent.existsSync(), isTrue);
  });

  test('keeps a file whose name is mentioned anywhere in a content row',
      () async {
    final img = file('elyanotes_images/odd.png');
    final doc = await create('A');
    await saveRaw(doc.id, json.encode({'note': 'see odd.png somewhere'}));

    expect(await sweep(), 0);
    expect(img.existsSync(), isTrue);
  });

  test('keeps files whose names JSON would escape', () async {
    final quoted = file('elyanotes_images/a"b.png');
    final slashed = file(r'elyanotes_images/a\b.png');

    expect(await sweep(), 0);
    expect(quoted.existsSync(), isTrue);
    expect(slashed.existsSync(), isTrue);
  });

  test('never touches other directories, subdirectories or symlinks', () async {
    final root = file('root.png');
    final other = file('somewhere_else.png');
    Directory('${dir.path}/pdfs/sub').createSync();
    final nested = file('pdfs/sub/nested.pdf');
    final target = file('target.png');
    Link('${dir.path}/elyanotes_images/link.png').createSync(target.path);

    expect(await sweep(), 0);

    expect(root.existsSync(), isTrue);
    expect(other.existsSync(), isTrue);
    expect(nested.existsSync(), isTrue);
    expect(target.existsSync(), isTrue);
    expect(
      FileSystemEntity.isLinkSync('${dir.path}/elyanotes_images/link.png'),
      isTrue,
    );
  });

  test('missing directories are fine', () async {
    Directory('${dir.path}/pdfs').deleteSync();
    Directory('${dir.path}/elyanotes_images').deleteSync();

    expect(await sweep(), 0);
  });

  test('a passthrough resolver sweeps nothing', () async {
    final plain = LibraryFixture();
    addTearDown(plain.close);
    final img = file('elyanotes_images/orphan.png');

    final result = await plain.documents.sweepOrphanedFiles(olderThan: cutoff);

    expect(result, const Right<Failure, int>(0));
    expect(img.existsSync(), isTrue);
  });
}
