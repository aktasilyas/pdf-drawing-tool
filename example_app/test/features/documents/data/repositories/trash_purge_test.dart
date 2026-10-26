import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/library_fixture.dart';

/// Trash retention, permanent delete and "empty trash" against real Drift.
void main() {
  late LibraryFixture fx;
  late Directory dir;
  final now = DateTime(2026, 6, 30, 12);
  final old = now.subtract(const Duration(days: 31));
  final recent = now.subtract(const Duration(days: 29));

  setUp(() {
    fx = LibraryFixture();
    dir = Directory.systemTemp.createTempSync('elya_trash_');
  });
  tearDown(() async {
    await fx.close();
    dir.deleteSync(recursive: true);
  });

  Future<DocumentInfo> create(String title) async =>
      (await fx.documents.createDocument(title: title, templateId: 'blank'))
          .getOrElse(() => throw StateError('create failed'));

  Future<void> trashAt(String id, DateTime? deletedAt) async {
    final doc = await fx.documentDs.getDocument(id);
    await fx.documentDs.updateDocument(
      doc.restored(doc.folderId, doc.updatedAt).copyWith(isInTrash: true),
    );
    if (deletedAt != null) {
      final trashed = await fx.documentDs.getDocument(id);
      await fx.documentDs
          .updateDocument(trashed.copyWith(deletedAt: deletedAt));
    }
  }

  Future<void> addPage(String id, String docId, DateTime at,
      [Map<String, dynamic>? data]) {
    return fx.trashDs.addTrashedPage(TrashedPageModel(
      id: id,
      pageId: 'p-$id',
      sourceDocumentId: docId,
      sourceDocumentTitle: 'T',
      originalPageIndex: 0,
      deletedAt: at,
      pageData: data ?? {'id': 'p-$id'},
    ));
  }

  Map<String, dynamic> pdfContent(String path) => {
        'pages': [
          {
            'id': 'p0',
            'index': 0,
            'background': {'type': 'pdf', 'pdfFilePath': path},
          },
        ],
      };

  group('deletedAt', () {
    test('moveToTrash stamps deletedAt and restore clears it', () async {
      final d = await create('Doc');
      expect(d.deletedAt, isNull);

      await fx.documents.moveToTrash(d.id);
      final trashed = await fx.documentDs.getDocument(d.id);
      expect(trashed.isInTrash, isTrue);
      expect(trashed.deletedAt, isNotNull);

      await fx.documents.restoreFromTrash(d.id);
      final back = await fx.documentDs.getDocument(d.id);
      expect(back.isInTrash, isFalse);
      expect(back.deletedAt, isNull);
    });
  });

  group('purge expired', () {
    late PurgeExpiredTrashUseCase purge;
    setUp(() => purge = PurgeExpiredTrashUseCase(fx.documents, fx.pageTrash));

    test('removes documents trashed over 30 days ago, keeps newer', () async {
      final expired = await create('Expired');
      final fresh = await create('Fresh');
      final live = await create('Live');
      await fx.documents.saveDocumentContent(id: expired.id, content: {
        'pages': <dynamic>[],
      });
      await trashAt(expired.id, old);
      await trashAt(fresh.id, recent);

      final r = await purge(now);

      expect(r.isRight(), isTrue);
      final ids = (await fx.documentDs.getAllDocuments()).map((d) => d.id);
      expect(ids, unorderedEquals([fresh.id, live.id]));
      expect(await fx.documentDs.hasDocumentContent(expired.id), isFalse);
    });

    test('stamps legacy trashed documents instead of purging them', () async {
      final legacy = await create('Legacy');
      await trashAt(legacy.id, null);

      await purge(now);

      final doc = await fx.documentDs.getDocument(legacy.id);
      expect(doc.isInTrash, isTrue);
      expect(doc.deletedAt, now);
      // And it survives a purge 29 days later, but not one 31 days later.
      await purge(now.add(const Duration(days: 29)));
      expect(await fx.documentDs.getAllDocuments(), hasLength(1));
      await purge(now.add(const Duration(days: 31)));
      expect(await fx.documentDs.getAllDocuments(), isEmpty);
    });

    test('removes expired trashed pages only', () async {
      final d = await create('Doc');
      await addPage('old', d.id, old);
      await addPage('new', d.id, recent);

      await purge(now);

      final left = await fx.pageTrash.getTrashedPages();
      expect(left.map((p) => p.id), ['new']);
    });
  });

  group('permanentlyDelete', () {
    test('removes content, row and that document\'s trashed pages', () async {
      final a = await create('A');
      final b = await create('B');
      await fx.documents.saveDocumentContent(
        id: a.id,
        content: {'pages': <dynamic>[]},
      );
      await addPage('ta', a.id, recent);
      await addPage('tb', b.id, recent);

      final r = await fx.documents.permanentlyDelete(a.id);

      expect(r.isRight(), isTrue);
      expect(await fx.documentDs.hasDocumentContent(a.id), isFalse);
      expect((await fx.documentDs.getAllDocuments()).map((d) => d.id), [b.id]);
      expect((await fx.pageTrash.getTrashedPages()).map((p) => p.id), ['tb']);
    });

    test('deletes the copied PDF unless another document uses it', () async {
      final shared = File('${dir.path}/shared.pdf')..writeAsStringSync('x');
      final own = File('${dir.path}/own.pdf')..writeAsStringSync('x');
      final a = await create('A');
      final b = await create('B');
      final c = await create('C');
      await fx.documents
          .saveDocumentContent(id: a.id, content: pdfContent(shared.path));
      await fx.documents
          .saveDocumentContent(id: b.id, content: pdfContent(shared.path));
      await fx.documents
          .saveDocumentContent(id: c.id, content: pdfContent(own.path));

      await fx.documents.permanentlyDelete(a.id);
      expect(shared.existsSync(), isTrue);

      await fx.documents.permanentlyDelete(c.id);
      expect(own.existsSync(), isFalse);

      await fx.documents.permanentlyDelete(b.id);
      expect(shared.existsSync(), isFalse);
    });

    test('keeps the PDF while another document\'s trashed page uses it',
        () async {
      final pdf = File('${dir.path}/p.pdf')..writeAsStringSync('x');
      final a = await create('A');
      final b = await create('B');
      await fx.documents
          .saveDocumentContent(id: a.id, content: pdfContent(pdf.path));
      await addPage('tb', b.id, recent, {
        'id': 'x',
        'background': {'pdfFilePath': pdf.path},
      });

      await fx.documents.permanentlyDelete(a.id);

      expect(pdf.existsSync(), isTrue);
    });

    test('restoring a page of a deleted notebook reports a missing source',
        () async {
      final a = await create('A');
      await fx.documents.saveDocumentContent(id: a.id, content: {
        'pages': [
          {'id': 'p0', 'index': 0},
        ],
      });
      final id = await fx.pageTrash.movePageToTrash(
        documentId: a.id,
        documentTitle: a.title,
        pageIndex: 0,
        pageData: {'id': 'gone'},
      );
      await fx.documents.permanentlyDelete(a.id);

      expect(await fx.pageTrash.documentExists(a.id), isFalse);
      expect(await fx.pageTrash.restorePageFromTrash(id), isFalse);
      expect(await fx.documentDs.getAllDocuments(), isEmpty);
      expect(await fx.pageTrash.getTrashedPages(), isEmpty);
    });
  });

  test('emptyTrash deletes trashed documents and pages, not live ones',
      () async {
    final live = await create('Live');
    final gone = await create('Gone');
    await trashAt(gone.id, recent);
    await addPage('t1', live.id, recent);

    final docs = await fx.documents.emptyTrash();
    final pages = await fx.pageTrash.emptyTrash();

    expect(docs.getOrElse(() => -1), 1);
    expect(pages, 1);
    expect((await fx.documentDs.getAllDocuments()).map((d) => d.id), [live.id]);
    expect(await fx.pageTrash.getTrashedPages(), isEmpty);
  });
}
