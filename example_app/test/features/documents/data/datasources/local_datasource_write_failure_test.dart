import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/pass_through_runner.dart';
import '../../../../helpers/rejecting_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await rejectLibraryWrites(db);
  });
  tearDown(() => db.close());

  final now = DateTime(2026, 1, 1);

  group('a rejected Drift write throws CacheException', () {
    test('document content', () {
      final ds = DocumentLocalDatasourceImpl(db);
      expect(
        ds.saveDocumentContent('doc-1', {'pages': <dynamic>[]}),
        throwsA(isA<CacheException>()),
      );
    });

    test('document metadata', () {
      final ds = DocumentLocalDatasourceImpl(db);
      final doc = DocumentModel(
        id: 'doc-1',
        title: 'Notes',
        templateId: 'blank',
        createdAt: now,
        updatedAt: now,
      );
      expect(ds.createDocument(doc), throwsA(isA<CacheException>()));
    });

    test('folders', () {
      final ds = FolderLocalDatasourceImpl(db);
      final folder = FolderModel(id: 'f1', name: 'Ders', createdAt: now);
      expect(ds.createFolder(folder), throwsA(isA<CacheException>()));
    });

    test('trashed pages', () {
      final ds = TrashedPageLocalDatasourceImpl(db);
      final page = TrashedPageModel(
        id: 't1',
        pageId: 'p1',
        sourceDocumentId: 'doc-1',
        sourceDocumentTitle: 'Notes',
        originalPageIndex: 0,
        deletedAt: now,
        pageData: const {},
      );
      expect(ds.addTrashedPage(page), throwsA(isA<CacheException>()));
    });
  });

  test('a successful write does not throw', () async {
    final healthy = AppDatabase(NativeDatabase.memory());
    addTearDown(healthy.close);
    final ds = DocumentLocalDatasourceImpl(healthy);
    await ds.saveDocumentContent('doc-1', {'pages': <dynamic>[]});
    expect(await ds.getDocumentContent('doc-1'), {'pages': <dynamic>[]});
  });

  test('the repository turns a rejected content write into a Failure',
      () async {
    final repo = DocumentRepositoryImpl(
      DocumentLocalDatasourceImpl(db),
      FolderLocalDatasourceImpl(db),
      PassThroughRunner(),
    );
    final result = await repo.saveDocumentContent(
      id: 'doc-1',
      content: {'pages': <dynamic>[]},
    );
    expect(result.isLeft(), isTrue);
  });
}
