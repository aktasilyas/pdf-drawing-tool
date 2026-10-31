import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart' show DocumentType;
import 'package:example_app/core/core.dart' show Failure;
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/library_fixture.dart';

/// Behaviour of the repositories against a real Drift database.
void main() {
  late LibraryFixture fx;

  setUp(() => fx = LibraryFixture());
  tearDown(() => fx.close());

  Future<DocumentInfo> create(String title, {String? folderId}) async =>
      (await fx.documents.createDocument(
        title: title,
        templateId: 'blank',
        folderId: folderId,
      ))
          .getOrElse(() => throw StateError('create failed'));

  Future<Folder> folder(String name, {String? parentId}) async =>
      (await fx.folders.createFolder(name: name, parentId: parentId))
          .getOrElse(() => throw StateError('folder failed'));

  Map<String, dynamic> content(int pages, {String id = 'content-id'}) => {
        'id': id,
        'pages': [
          for (var i = 0; i < pages; i++) {'id': 'p$i', 'index': i},
        ],
      };

  test('rename keeps the other fields', () async {
    final d = await create('Old');
    final r = await fx.documents.updateDocument(id: d.id, title: 'New');
    expect(r.getOrElse(() => throw StateError('x')).title, 'New');
    final back = (await fx.documents.getDocument(d.id)).toOption().toNullable();
    expect(back!.title, 'New');
    expect(back.pageCount, d.pageCount);
  });

  test('move into a folder and back to the root', () async {
    final f = await folder('Okul');
    final d = await create('Doc');
    await fx.documents.moveDocument(d.id, f.id);
    var docs =
        (await fx.documents.getDocuments(folderId: f.id)).getOrElse(() => []);
    expect(docs.map((x) => x.id), [d.id]);

    await fx.documents.moveDocument(d.id, null);
    docs = (await fx.documents.getDocuments()).getOrElse(() => []);
    expect(docs.map((x) => x.id), [d.id]);
    expect((await fx.documents.getDocuments(folderId: f.id)).isRight(), isTrue);
  });

  test('trash then restore returns the document', () async {
    final d = await create('Doc');
    await fx.documents.moveToTrash(d.id);
    expect((await fx.documents.getDocuments()).getOrElse(() => []), isEmpty);
    expect((await fx.documents.getTrash()).getOrElse(() => []), hasLength(1));

    await fx.documents.restoreFromTrash(d.id);
    expect(
        (await fx.documents.getDocuments()).getOrElse(() => []), hasLength(1));
    expect((await fx.documents.getTrash()).getOrElse(() => []), isEmpty);
  });

  test('restore falls back to the root when the folder is gone', () async {
    final f = await folder('Okul');
    final d = await create('Doc', folderId: f.id);
    await fx.documents.moveToTrash(d.id);
    await fx.folderDs.deleteFolder(f.id);

    await fx.documents.restoreFromTrash(d.id);
    final restored =
        (await fx.documents.getDocument(d.id)).toOption().toNullable()!;
    expect(restored.folderId, isNull);
    expect(restored.isInTrash, isFalse);
  });

  test('permanent delete removes the row and its content', () async {
    final d = await create('Doc');
    await fx.documents.saveDocumentContent(id: d.id, content: content(2));
    await fx.documents.moveToTrash(d.id);

    expect((await fx.documents.permanentlyDelete(d.id)).isRight(), isTrue);
    expect((await fx.documents.getDocument(d.id)).isLeft(), isTrue);
    expect(await fx.documentDs.hasDocumentContent(d.id), isFalse);
  });

  test('duplicate copies metadata and content under a new id', () async {
    final d = await create('Doc');
    await fx.documents.updateDocument(id: d.id, pageCount: 3);
    await fx.documents.saveDocumentContent(id: d.id, content: content(3));
    await fx.documents.toggleFavorite(d.id);

    final copy = (await fx.documents.duplicateDocument(
      d.id,
      copyTitle: (t) => '$t (copy)',
    ))
        .getOrElse(() => throw StateError('dup failed'));
    expect(copy.id, isNot(d.id));
    expect(copy.title, 'Doc (copy)');
    expect(copy.pageCount, 3);
    expect(copy.isFavorite, isFalse);
    final copied = (await fx.documents.getDocumentContent(copy.id))
        .toOption()
        .toNullable();
    // The copy's content points at the copy, not at the original.
    expect(copied, content(3, id: copy.id));
    // The original is untouched.
    expect(
        (await fx.documents.getDocumentContent(d.id)).toOption().toNullable(),
        content(3));
  });

  test('duplicate is all-or-nothing when the content copy fails', () async {
    final d = await create('Doc');
    await fx.documents.saveDocumentContent(id: d.id, content: content(1));
    await fx.db.customStatement(
      'CREATE TRIGGER no_copy BEFORE INSERT ON document_contents '
      "BEGIN SELECT RAISE(ABORT, 'no space'); END",
    );

    final r = await fx.documents.duplicateDocument(
      d.id,
      copyTitle: (t) => '$t (copy)',
    );
    expect(r.isLeft(), isTrue);
    expect(await fx.documentDs.getAllDocuments(), hasLength(1));
  });

  group('createDocumentWithContent (#602)', () {
    Future<Either<Failure, DocumentInfo>> importDoc({required int pages}) =>
        fx.documents.createDocumentWithContent(
          title: 'Imported',
          templateId: 'blank',
          documentType: DocumentType.pdf,
          pageCount: pages,
          buildContent: (doc) => content(pages, id: doc.id),
        );

    test('writes the row and its content under the same id', () async {
      final r = await importDoc(pages: 3);
      final doc = r.getOrElse(() => throw StateError('import failed'));
      final row = await fx.documentDs.getDocument(doc.id);
      expect(row.title, 'Imported');
      expect(row.pageCount, 3);
      expect(
        (await fx.documents.getDocumentContent(doc.id)).toOption().toNullable(),
        content(3, id: doc.id),
      );
    });

    test('leaves no row behind when the content write fails', () async {
      await fx.db.customStatement(
        'CREATE TRIGGER no_content BEFORE INSERT ON document_contents '
        "BEGIN SELECT RAISE(ABORT, 'no space'); END",
      );
      final r = await importDoc(pages: 1);
      expect(r.isLeft(), isTrue);
      expect(await fx.documentDs.getAllDocuments(), isEmpty);
    });

    test('leaves no row behind when building the content throws', () async {
      final r = await fx.documents.createDocumentWithContent(
        title: 'Imported',
        templateId: 'blank',
        pageCount: 1,
        buildContent: (_) => throw StateError('encode'),
      );
      expect(r.isLeft(), isTrue);
      expect(await fx.documentDs.getAllDocuments(), isEmpty);
    });
  });

  test('deleting a folder trashes its documents and subfolders', () async {
    final root = await folder('Okul');
    final sub = await folder('Ders', parentId: root.id);
    final inRoot = await create('A', folderId: root.id);
    final inSub = await create('B', folderId: sub.id);
    final outside = await create('C');

    final r = await fx.folders.deleteFolder(root.id);
    expect(r.isRight(), isTrue);
    expect((await fx.folders.getFolders()).getOrElse(() => []), isEmpty);
    final trash = (await fx.documents.getTrash()).getOrElse(() => []);
    expect(trash.map((x) => x.id), unorderedEquals([inRoot.id, inSub.id]));
    final live = (await fx.documents.getDocuments()).getOrElse(() => []);
    expect(live.map((x) => x.id), [outside.id]);
  });

  test('deleting a folder trashes notes at every depth and returns the count',
      () async {
    final root = await folder('Okul');
    final sub = await folder('Ders', parentId: root.id);
    final subsub = await folder('Hafta', parentId: sub.id);
    final a = await create('A', folderId: root.id);
    final b = await create('B', folderId: sub.id);
    final c = await create('C', folderId: subsub.id);

    final r = await fx.folders.deleteFolder(root.id);
    expect(r.getOrElse(() => -1), 3);
    expect((await fx.folders.getFolders()).getOrElse(() => []), isEmpty);
    final trash = (await fx.documents.getTrash()).getOrElse(() => []);
    expect(trash.map((x) => x.id), unorderedEquals([a.id, b.id, c.id]));
  });

  test('deleting an empty folder returns zero', () async {
    final root = await folder('Bos');
    final r = await fx.folders.deleteFolder(root.id);
    expect(r.getOrElse(() => -1), 0);
  });

  test('folder delete rolls back when a document update fails', () async {
    final root = await folder('Okul');
    await create('A', folderId: root.id);
    await fx.db.customStatement(
      'CREATE TRIGGER no_trash BEFORE UPDATE ON documents '
      "BEGIN SELECT RAISE(ABORT, 'rejected'); END",
    );
    final r = await fx.folders.deleteFolder(root.id);
    expect(r.isLeft(), isTrue);
    expect((await fx.folders.getFolders()).getOrElse(() => []), hasLength(1));
  });
}
