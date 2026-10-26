import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';
import 'package:example_app/features/documents/documents.dart';

class _RejectingPrefs extends Mock implements SharedPreferences {}

void main() {
  late _RejectingPrefs prefs;

  setUp(() {
    prefs = _RejectingPrefs();
    when(() => prefs.getString(any())).thenReturn(null);
    // SharedPreferences reports a failed platform write with `false`.
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => false);
  });

  final now = DateTime(2026, 1, 1);

  group('a rejected SharedPreferences write throws CacheException', () {
    test('document content', () {
      final ds = DocumentLocalDatasourceImpl(prefs);
      expect(
        ds.saveDocumentContent('doc-1', {'pages': <dynamic>[]}),
        throwsA(isA<CacheException>()),
      );
    });

    test('document metadata', () {
      final ds = DocumentLocalDatasourceImpl(prefs);
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
      final ds = FolderLocalDatasourceImpl(prefs);
      final folder = FolderModel(id: 'f1', name: 'Ders', createdAt: now);
      expect(ds.createFolder(folder), throwsA(isA<CacheException>()));
    });

    test('trashed pages', () {
      final ds = TrashedPageLocalDatasourceImpl(prefs);
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
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);
    final ds = DocumentLocalDatasourceImpl(prefs);
    await ds.saveDocumentContent('doc-1', {'pages': <dynamic>[]});
    verify(() => prefs.setString('document_content_doc-1', any())).called(1);
  });

  test('the repository turns a rejected content write into a Failure',
      () async {
    final repo = DocumentRepositoryImpl(
      DocumentLocalDatasourceImpl(prefs),
      FolderLocalDatasourceImpl(prefs),
    );
    final result = await repo.saveDocumentContent(
      id: 'doc-1',
      content: {'pages': <dynamic>[]},
    );
    expect(result.isLeft(), isTrue);
  });
}
