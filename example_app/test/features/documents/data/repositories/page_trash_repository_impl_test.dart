import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart' show Failure;
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import '../../../../helpers/library_fixture.dart';

/// [PageTrashRepositoryImpl] against a real Drift database.
void main() {
  late LibraryFixture fx;
  late Directory dir;

  setUp(() {
    fx = LibraryFixture();
    dir = Directory.systemTemp.createTempSync('elya_page_trash_');
  });
  tearDown(() async {
    await fx.close();
    dir.deleteSync(recursive: true);
  });

  T ok<T>(Either<Failure, T> result) =>
      result.getOrElse(() => throw StateError('unexpected failure'));

  Future<DocumentInfo> create(String title) async =>
      ok(await fx.documents.createDocument(title: title, templateId: 'blank'));

  Future<List<TrashedPage>> trashedPages() async =>
      ok(await fx.pageTrash.getTrashedPages());

  Future<String> trash(
    String documentId, {
    int pageIndex = 0,
    Map<String, dynamic>? pageData,
  }) async =>
      ok(await fx.pageTrash.movePageToTrash(
        documentId: documentId,
        documentTitle: 'T',
        pageIndex: pageIndex,
        pageData: pageData ?? {'id': 'gone', 'index': pageIndex},
      ));

  Map<String, dynamic> content(int pages) => {
        'pages': [
          for (var i = 0; i < pages; i++) {'id': 'p$i', 'index': i},
        ],
      };

  Map<String, dynamic> pdfPage(File pdf) => {
        'id': 'pdf-page',
        'background': {'type': 'pdf', 'pdfFilePath': pdf.path},
      };

  File pdfFile(String name) =>
      File('${dir.path}/$name')..writeAsStringSync('x');

  group('move to trash', () {
    test('two pages trashed in the same millisecond get distinct ids',
        () async {
      final ids = await Future.wait([trash('d'), trash('d')]);

      expect(ids.toSet(), hasLength(2));
      expect(await trashedPages(), hasLength(2));
    });

    test('stores the page with its source and position', () async {
      final id = await trash('d', pageIndex: 3);

      final page = (await trashedPages()).single;
      expect(page.id, id);
      expect(page.sourceDocumentId, 'd');
      expect(page.originalPageIndex, 3);
    });
  });

  group('restore', () {
    test('re-inserts the page, re-indexes and updates the count', () async {
      final d = await create('Doc');
      await fx.documents
          .saveDocumentContent(id: d.id, content: content(3), pageCount: 3);
      final id = await trash(d.id, pageIndex: 1);
      expect(await fx.pageTrash.documentExists(d.id), const Right(true));

      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      final pages = (await fx.documentDs.getDocumentContent(d.id))!['pages']
          as List<dynamic>;
      expect(pages.map((p) => (p as Map)['id']), ['p0', 'gone', 'p1', 'p2']);
      expect(pages.map((p) => (p as Map)['index']), [0, 1, 2, 3]);
      expect((await fx.documentDs.getDocument(d.id)).pageCount, 4);
      expect(await trashedPages(), isEmpty);
    });

    test('a page already back in the notebook is not inserted twice', () async {
      final d = await create('Doc');
      await fx.documents
          .saveDocumentContent(id: d.id, content: content(3), pageCount: 3);
      // p1 was trashed, then re-inserted by an editor undo; the row stayed.
      final id = await trash(d.id, pageIndex: 1, pageData: {'id': 'p1'});

      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      final pages = (await fx.documentDs.getDocumentContent(d.id))!['pages']
          as List<dynamic>;
      expect(pages.map((p) => (p as Map)['id']), ['p0', 'p1', 'p2']);
      expect((await fx.documentDs.getDocument(d.id)).pageCount, 3);
      expect(await trashedPages(), isEmpty);
    });

    test('restoring before the current page keeps that page current', () async {
      final d = await create('Doc');
      await fx.documents.saveDocumentContent(
        id: d.id,
        content: {...content(3), 'currentPageIndex': 2},
        pageCount: 3,
      );
      final id = await trash(d.id, pageIndex: 1);

      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      final stored = (await fx.documentDs.getDocumentContent(d.id))!;
      final pages = stored['pages'] as List<dynamic>;
      expect(stored['currentPageIndex'], 3);
      expect((pages[3] as Map)['id'], 'p2');
    });

    test('restoring at the current position keeps that page current', () async {
      final d = await create('Doc');
      await fx.documents.saveDocumentContent(
        id: d.id,
        content: {...content(3), 'currentPageIndex': 1},
        pageCount: 3,
      );
      final id = await trash(d.id, pageIndex: 1);

      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      final stored = (await fx.documentDs.getDocumentContent(d.id))!;
      final pages = stored['pages'] as List<dynamic>;
      expect(stored['currentPageIndex'], 2);
      expect((pages[2] as Map)['id'], 'p1');
      expect((pages[1] as Map)['id'], 'gone');
    });

    test('restoring after the current page leaves the index alone', () async {
      final d = await create('Doc');
      await fx.documents.saveDocumentContent(
        id: d.id,
        content: {...content(3), 'currentPageIndex': 0},
        pageCount: 3,
      );
      final id = await trash(d.id, pageIndex: 2);

      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      final stored = (await fx.documentDs.getDocumentContent(d.id))!;
      expect(stored['currentPageIndex'], 0);
    });

    test('never lands before a cover and keeps the current page', () async {
      final d = await create('Doc');
      final withCover = content(3);
      (withCover['pages'] as List)[0] = {
        'id': 'cover',
        'index': 0,
        'isCover': true
      };
      await fx.documents.saveDocumentContent(
        id: d.id,
        content: {...withCover, 'currentPageIndex': 1},
        pageCount: 3,
      );
      final id = await trash(d.id, pageIndex: 0);

      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      final stored = (await fx.documentDs.getDocumentContent(d.id))!;
      final pages = stored['pages'] as List<dynamic>;
      expect((pages[0] as Map)['id'], 'cover');
      expect((pages[1] as Map)['id'], 'gone');
      expect(stored['currentPageIndex'], 2);
      expect((pages[2] as Map)['id'], 'p1');
    });

    test('a coverless notebook still restores to the first position', () async {
      final d = await create('Doc');
      await fx.documents
          .saveDocumentContent(id: d.id, content: content(2), pageCount: 2);
      final id = await trash(d.id, pageIndex: 0);

      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      final stored = (await fx.documentDs.getDocumentContent(d.id))!;
      expect(((stored['pages'] as List)[0] as Map)['id'], 'gone');
    });

    test('clamps an index past the end to the last position', () async {
      final d = await create('Doc');
      await fx.documents
          .saveDocumentContent(id: d.id, content: content(2), pageCount: 2);
      final id = await trash(d.id, pageIndex: 9);

      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      final pages = (await fx.documentDs.getDocumentContent(d.id))!['pages']
          as List<dynamic>;
      expect(pages.map((p) => (p as Map)['id']), ['p0', 'p1', 'gone']);
      expect(pages.map((p) => (p as Map)['index']), [0, 1, 2]);
      expect((await fx.documentDs.getDocument(d.id)).pageCount, 3);
    });

    test('without content gives false and keeps the trashed page', () async {
      final id = await trash('missing');

      expect(await fx.pageTrash.documentExists('missing'), const Right(false));
      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(false));
      expect(await trashedPages(), hasLength(1));
    });

    test('a notebook in the trash is not a restore target', () async {
      final d = await create('Doc');
      await fx.documents
          .saveDocumentContent(id: d.id, content: content(2), pageCount: 2);
      final id = await trash(d.id, pageIndex: 1);
      ok(await fx.documents.moveToTrash(d.id));

      expect(await fx.pageTrash.documentExists(d.id), const Right(false));
      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(false));
      expect(await trashedPages(), hasLength(1), reason: 'trash row stays');
      final pages = (await fx.documentDs.getDocumentContent(d.id))!['pages']
          as List<dynamic>;
      expect(pages, hasLength(2), reason: 'hidden notebook is untouched');

      // Once the notebook is back, the page can be restored into it.
      ok(await fx.documents.restoreFromTrash(d.id));
      expect(await fx.pageTrash.documentExists(d.id), const Right(true));
      expect(await fx.pageTrash.restorePageFromTrash(id), const Right(true));
      expect(await trashedPages(), isEmpty);
    });

    test('a failure mid-restore rolls everything back', () async {
      final d = await create('Doc');
      await fx.documents
          .saveDocumentContent(id: d.id, content: content(2), pageCount: 2);
      final id = await trash(d.id);
      await fx.db.customStatement(
        'CREATE TRIGGER no_count BEFORE UPDATE ON documents '
        "BEGIN SELECT RAISE(ABORT, 'rejected'); END",
      );

      final result = await fx.pageTrash.restorePageFromTrash(id);

      expect(result.isLeft(), isTrue);
      final pages = (await fx.documentDs.getDocumentContent(d.id))!['pages']
          as List<dynamic>;
      expect(pages, hasLength(2));
      expect(await trashedPages(), hasLength(1));
    });
  });

  group('permanent delete', () {
    test('removes the trashed page', () async {
      final id = await trash('d');

      expect((await fx.pageTrash.permanentlyDeletePage(id)).isRight(), isTrue);
      expect(await trashedPages(), isEmpty);
    });

    test('deletes a PDF only the trashed page referenced', () async {
      final pdf = pdfFile('only.pdf');
      final id = await trash('d', pageData: pdfPage(pdf));

      await fx.pageTrash.permanentlyDeletePage(id);

      expect(pdf.existsSync(), isFalse);
    });

    test('keeps a PDF another document still uses', () async {
      final pdf = pdfFile('shared.pdf');
      final d = await create('Doc');
      await fx.documents.saveDocumentContent(id: d.id, content: {
        'pages': [pdfPage(pdf)],
      });
      final id = await trash(d.id, pageData: pdfPage(pdf));

      await fx.pageTrash.permanentlyDeletePage(id);

      expect(pdf.existsSync(), isTrue);
    });

    test('keeps a PDF another trashed page still uses', () async {
      final pdf = pdfFile('twice.pdf');
      final first = await trash('d', pageData: pdfPage(pdf));
      final second = await trash('d', pageData: pdfPage(pdf));

      await fx.pageTrash.permanentlyDeletePage(first);
      expect(pdf.existsSync(), isTrue);

      await fx.pageTrash.permanentlyDeletePage(second);
      expect(pdf.existsSync(), isFalse);
    });
  });

  test('emptyTrash removes every page and their unused PDFs', () async {
    final pdf = pdfFile('empty.pdf');
    await trash('a', pageData: pdfPage(pdf));
    await trash('b');

    expect(await fx.pageTrash.emptyTrash(), const Right(2));
    expect(await trashedPages(), isEmpty);
    expect(pdf.existsSync(), isFalse);
  });

  group('purgeExpired', () {
    final now = DateTime(2026, 6, 30, 12);

    Future<void> addAt(String id, DateTime at, Map<String, dynamic> data) {
      return fx.trashDs.addTrashedPage(TrashedPageModel(
        id: id,
        pageId: 'p-$id',
        sourceDocumentId: 'd',
        sourceDocumentTitle: 'T',
        originalPageIndex: 0,
        deletedAt: at,
        pageData: data,
      ));
    }

    test('removes expired pages and their unused PDFs only', () async {
      final oldPdf = pdfFile('old.pdf');
      final newPdf = pdfFile('new.pdf');
      final old = now.subtract(const Duration(days: 31));
      final recent = now.subtract(const Duration(days: 29));
      await addAt('old', old, pdfPage(oldPdf));
      await addAt('new', recent, pdfPage(newPdf));

      expect(await fx.pageTrash.purgeExpired(now: now), const Right(1));

      expect((await trashedPages()).map((p) => p.id), ['new']);
      expect(oldPdf.existsSync(), isFalse);
      expect(newPdf.existsSync(), isTrue);
    });
  });

  group('unreadable row', () {
    final now = DateTime(2026, 6, 30, 12);

    Future<void> addCorrupt(String id, DateTime at) {
      return fx.db.customStatement(
        'INSERT INTO trashed_pages (id, page_id, source_document_id, '
        'source_document_title, original_page_index, deleted_at, page_data) '
        "VALUES (?, 'p', 'd', 'T', 0, ?, '{not json')",
        [id, at.millisecondsSinceEpoch ~/ 1000],
      );
    }

    test('is skipped by the list while valid rows stay', () async {
      final good = await trash('d');
      await addCorrupt('bad', now);

      expect((await trashedPages()).map((p) => p.id), [good]);
    });

    test('emptyTrash removes it with the valid rows', () async {
      await trash('d');
      await addCorrupt('bad', now);

      expect(await fx.pageTrash.emptyTrash(), const Right(2));
      expect(await trashedPages(), isEmpty);
      expect(await fx.trashDs.getUnreadableTrashedPages(), isEmpty);
    });

    test('purgeExpired removes an expired one and keeps a recent one',
        () async {
      await addCorrupt('old', now.subtract(const Duration(days: 31)));
      await addCorrupt('new', now.subtract(const Duration(days: 1)));
      final good = await trash('d');

      expect(await fx.pageTrash.purgeExpired(now: now), const Right(1));
      expect((await fx.trashDs.getUnreadableTrashedPages()).map((u) => u.id),
          ['new']);
      expect((await trashedPages()).map((p) => p.id), [good]);
    });

    test('permanent delete removes it by id', () async {
      await addCorrupt('bad', now);

      expect(
          (await fx.pageTrash.permanentlyDeletePage('bad')).isRight(), isTrue);
      expect(await fx.trashDs.getUnreadableTrashedPages(), isEmpty);
    });
  });
}
