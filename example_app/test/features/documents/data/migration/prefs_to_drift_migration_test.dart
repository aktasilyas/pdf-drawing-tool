import 'dart:convert';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  final now = DateTime(2026, 1, 1);

  DocumentModel doc(String id, {String? folderId}) => DocumentModel(
        id: id,
        title: 'Doc $id',
        folderId: folderId,
        templateId: 'blank',
        createdAt: now,
        updatedAt: now,
        pageCount: 2,
        isFavorite: true,
      );

  final trashed = {
    'id': 't1',
    'page_id': 'p1',
    'source_document_id': 'd1',
    'source_document_title': 'Doc d1',
    'original_page_index': 1,
    'deleted_at': now.toIso8601String(),
    'page_data': {'id': 'p1', 'index': 1},
  };

  Future<void> seed({List<Object?>? extraDocs}) async {
    SharedPreferences.setMockInitialValues({
      'documents': json.encode([
        doc('d1', folderId: 'f1').toJson(),
        doc('d2').toJson(),
        ...?extraDocs,
      ]),
      'folders': json.encode([
        FolderModel(id: 'f1', name: 'Okul', createdAt: now).toJson(),
      ]),
      'trashed_pages': json.encode([trashed]),
      'document_content_d1': json.encode({'pages': <dynamic>[]}),
      'unrelated': 'keep me',
    });
    prefs = await SharedPreferences.getInstance();
  }

  PrefsToDriftMigration migration() => PrefsToDriftMigration(db, prefs);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('imports documents, folders, trashed pages and content', () async {
    await seed();
    await migration().run();

    final docs = await db.select(db.documents).get();
    expect(docs.map((d) => d.id), unorderedEquals(['d1', 'd2']));
    expect(docs.firstWhere((d) => d.id == 'd1').folderId, 'f1');
    expect(docs.first.isFavorite, isTrue);
    expect(await db.select(db.folders).get(), hasLength(1));
    final pages = await db.select(db.trashedPages).get();
    expect(pages.single.id, 't1');
    expect(json.decode(pages.single.pageData), {'id': 'p1', 'index': 1});
    final content = await db.select(db.documentContents).get();
    expect(content.single.documentId, 'd1');
  });

  test('removes migrated keys and sets the flag, other keys stay', () async {
    await seed();
    await migration().run();

    expect(prefs.containsKey('documents'), isFalse);
    expect(prefs.containsKey('folders'), isFalse);
    expect(prefs.containsKey('trashed_pages'), isFalse);
    expect(prefs.containsKey('document_content_d1'), isFalse);
    expect(prefs.getString('unrelated'), 'keep me');
    final flag = await (db.select(db.syncMetadata)
          ..where((t) => t.key.equals(PrefsToDriftMigration.flagKey)))
        .getSingleOrNull();
    expect(flag, isNotNull);
  });

  test('is idempotent: a second run changes nothing', () async {
    await seed();
    await migration().run();
    await db.update(db.documents).write(
          const DocumentsCompanion(title: Value('Edited in Drift')),
        );
    // Old data reappears (e.g. restored prefs); the flag blocks re-import.
    await seed();
    await migration().run();

    final docs = await db.select(db.documents).get();
    expect(docs, hasLength(2));
    expect(docs.every((d) => d.title == 'Edited in Drift'), isTrue);
    expect(prefs.containsKey('documents'), isTrue);
  });

  test('does not overwrite rows that already exist', () async {
    await seed();
    await db.into(db.documents).insert(
          DocumentsCompanion.insert(
            id: 'd1',
            title: 'Already here',
            templateId: 'blank',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await migration().run();
    final d1 = await (db.select(db.documents)..where((t) => t.id.equals('d1')))
        .getSingle();
    expect(d1.title, 'Already here');
  });

  test('corrupt entries are skipped and their keys kept', () async {
    await seed(extraDocs: [
      {'id': 'broken'},
    ]);
    await prefs.setString('document_content_d9', '{not json');
    await migration().run();

    final ids = (await db.select(db.documents).get()).map((d) => d.id);
    expect(ids, unorderedEquals(['d1', 'd2']));
    expect(prefs.containsKey('documents'), isTrue);
    expect(prefs.getString('document_content_d9'), '{not json');
    expect(prefs.containsKey('folders'), isFalse);
    expect(await db.select(db.documentContents).get(), hasLength(1));
  });

  test('empty prefs only set the flag', () async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await migration().run();
    expect(await db.select(db.documents).get(), isEmpty);
    expect(await db.select(db.syncMetadata).get(), hasLength(1));
  });
}
