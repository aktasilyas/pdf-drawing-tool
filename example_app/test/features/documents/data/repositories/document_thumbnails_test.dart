import 'dart:io';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/library_fixture.dart';

/// Library thumbnails are stored as managed files, against real Drift.
void main() {
  late LibraryFixture fx;
  late Directory dir;
  final png = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('elya_thumb_');
    fx = LibraryFixture(null, PdfPathResolver(dir.path));
  });
  tearDown(() async {
    await fx.close();
    dir.deleteSync(recursive: true);
  });

  Future<DocumentInfo> create(String title, {String? folderId}) async =>
      (await fx.documents.createDocument(
        title: title,
        templateId: 'blank',
        folderId: folderId,
      ))
          .getOrElse(() => throw StateError('create failed'));

  Future<String> save(String id) async =>
      (await fx.documents.saveThumbnail(id, png))
          .getOrElse(() => throw StateError('save failed'));

  File fileOf(String stored) => File('${dir.path}/$stored');

  test('writes the png and stores its relative path', () async {
    final doc = await create('A');

    final stored = await save(doc.id);

    expect(stored, startsWith('elyanotes_images/thumb_${doc.id}_'));
    expect(stored, endsWith('.png'));
    expect(fileOf(stored).readAsBytesSync(), png);
    final row = await fx.documentDs.getDocument(doc.id);
    expect(row.thumbnailPath, stored);
  });

  test('keeps the edited date and the folder', () async {
    final folder = (await fx.folders.createFolder(name: 'F'))
        .getOrElse(() => throw StateError('folder failed'));
    final doc = await create('A', folderId: folder.id);
    final before = await fx.documentDs.getDocument(doc.id);

    await save(doc.id);

    final after = await fx.documentDs.getDocument(doc.id);
    expect(after.updatedAt, before.updatedAt);
    expect(after.folderId, folder.id);
  });

  test('a second save deletes the first file', () async {
    final doc = await create('A');
    final first = await save(doc.id);

    final second = await save(doc.id);

    expect(second, isNot(first));
    expect(fileOf(first).existsSync(), isFalse);
    expect(fileOf(second).existsSync(), isTrue);
  });

  test('a previous path outside the managed files is never deleted',
      () async {
    final doc = await create('A');
    final own = File('${dir.path}/own.png')..writeAsBytesSync(png);
    final row = await fx.documentDs.getDocument(doc.id);
    await fx.documentDs.updateDocument(row.copyWith(thumbnailPath: own.path));

    await save(doc.id);

    expect(own.existsSync(), isTrue);
  });

  test('a file still used by a duplicate is kept', () async {
    final doc = await create('A');
    final first = await save(doc.id);
    final copy = (await fx.documents.duplicateDocument(
      doc.id,
      copyTitle: (t) => '$t (copy)',
    ))
        .getOrElse(() => throw StateError('duplicate failed'));
    expect(copy.thumbnailPath, first);

    final second = await save(doc.id);

    expect(fileOf(first).existsSync(), isTrue);
    expect(fileOf(second).existsSync(), isTrue);
  });

  test('permanent delete removes the thumbnail file', () async {
    final doc = await create('A');
    final stored = await save(doc.id);

    final result = await fx.documents.permanentlyDelete(doc.id);

    expect(result.isRight(), isTrue);
    expect(fileOf(stored).existsSync(), isFalse);
  });

  test('without a documents root it fails and writes nothing', () async {
    final plain = LibraryFixture();
    addTearDown(plain.close);
    final doc =
        (await plain.documents.createDocument(title: 'A', templateId: 'blank'))
            .getOrElse(() => throw StateError('create failed'));

    final result = await plain.documents.saveThumbnail(doc.id, png);

    expect(result.isLeft(), isTrue);
    expect(Directory('${dir.path}/elyanotes_images').existsSync(), isFalse);
  });

  test('a missing document fails and leaves no file behind', () async {
    final result = await fx.documents.saveThumbnail('missing', png);

    expect(result.isLeft(), isTrue);
    final images = Directory('${dir.path}/elyanotes_images');
    expect(images.listSync(), isEmpty);
  });

  test('deleteUnreferencedFiles keeps a path another row uses', () async {
    final doc = await create('A');
    final stored = await save(doc.id);

    await fx.documentDs.deleteUnreferencedFiles([stored]);

    expect(fileOf(stored).existsSync(), isTrue);
  });
}
