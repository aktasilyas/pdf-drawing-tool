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

  Map<String, dynamic> content(int pages) => {
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
    expect(copied, content(3));
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

  group('page trash', () {
    test('restore re-inserts the page, re-indexes and updates the count',
        () async {
      final d = await create('Doc');
      await fx.documents
          .saveDocumentContent(id: d.id, content: content(3), pageCount: 3);
      final id = await fx.pageTrash.movePageToTrash(
        documentId: d.id,
        documentTitle: d.title,
        pageIndex: 1,
        pageData: {'id': 'gone', 'index': 1},
      );
      expect(await fx.pageTrash.documentExists(d.id), isTrue);

      expect(await fx.pageTrash.restorePageFromTrash(id), isTrue);
      final pages = (await fx.documentDs.getDocumentContent(d.id))!['pages']
          as List<dynamic>;
      expect(pages.map((p) => (p as Map)['id']), ['p0', 'gone', 'p1', 'p2']);
      expect(pages.map((p) => (p as Map)['index']), [0, 1, 2, 3]);
      expect((await fx.documentDs.getDocument(d.id)).pageCount, 4);
      expect(await fx.pageTrash.getTrashedPages(), isEmpty);
    });

    test('restore fails without content and keeps the trashed page', () async {
      final id = await fx.pageTrash.movePageToTrash(
        documentId: 'missing',
        documentTitle: 'X',
        pageIndex: 0,
        pageData: {'id': 'p'},
      );
      expect(await fx.pageTrash.documentExists('missing'), isFalse);
      expect(await fx.pageTrash.restorePageFromTrash(id), isFalse);
      expect(await fx.pageTrash.getTrashedPages(), hasLength(1));
    });

    test('a failure mid-restore rolls everything back', () async {
      final d = await create('Doc');
      await fx.documents
          .saveDocumentContent(id: d.id, content: content(2), pageCount: 2);
      final id = await fx.pageTrash.movePageToTrash(
        documentId: d.id,
        documentTitle: d.title,
        pageIndex: 0,
        pageData: {'id': 'gone'},
      );
      await fx.db.customStatement(
        'CREATE TRIGGER no_count BEFORE UPDATE ON documents '
        "BEGIN SELECT RAISE(ABORT, 'rejected'); END",
      );

      expect(await fx.pageTrash.restorePageFromTrash(id), isFalse);
      final pages = (await fx.documentDs.getDocumentContent(d.id))!['pages']
          as List<dynamic>;
      expect(pages, hasLength(2));
      expect(await fx.pageTrash.getTrashedPages(), hasLength(1));
    });

    test('permanent delete removes the trashed page', () async {
      final id = await fx.pageTrash.movePageToTrash(
        documentId: 'd',
        documentTitle: 'X',
        pageIndex: 0,
        pageData: {'id': 'p'},
      );
      await fx.pageTrash.permanentlyDeletePage(id);
      expect(await fx.pageTrash.getTrashedPages(), isEmpty);
    });
  });
}
