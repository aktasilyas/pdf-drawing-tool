import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/pass_through_runner.dart';

class _MockDocumentLocalDatasource extends Mock
    implements DocumentLocalDatasource {}

class _MockFolderLocalDatasource extends Mock
    implements FolderLocalDatasource {}

class _MockUuid extends Mock implements Uuid {}

/// The "edited" date (`updatedAt`) drives date sorting, Recent and the
/// library thumbnail key, so only content or title changes may bump it
/// (#453).
void main() {
  final edited = DateTime(2024, 3, 1);
  final stored = DocumentModel(
    id: 'doc-1',
    title: 'Old notes',
    templateId: 'blank',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: edited,
  );

  late DocumentRepositoryImpl repository;
  late _MockDocumentLocalDatasource datasource;
  DocumentModel? saved;

  setUpAll(() => registerFallbackValue(stored));

  setUp(() {
    datasource = _MockDocumentLocalDatasource();
    repository = DocumentRepositoryImpl(
      datasource,
      _MockFolderLocalDatasource(),
      PassThroughRunner(),
      _MockUuid(),
    );
    saved = null;
    when(() => datasource.getDocument('doc-1')).thenAnswer((_) async => stored);
    when(() => datasource.updateDocument(any())).thenAnswer((invocation) async {
      return saved = invocation.positionalArguments[0] as DocumentModel;
    });
    when(() => datasource.saveDocumentContent(any(), any()))
        .thenAnswer((_) async {});
  });

  test('toggleFavorite keeps the edited date', () async {
    final result = await repository.toggleFavorite('doc-1');

    expect(result.isRight(), isTrue);
    expect(saved?.isFavorite, isTrue);
    expect(saved?.updatedAt, edited);
  });

  test('moveDocument keeps the edited date', () async {
    final result = await repository.moveDocument('doc-1', 'folder-1');

    expect(result.isRight(), isTrue);
    expect(saved?.folderId, 'folder-1');
    expect(saved?.updatedAt, edited);
  });

  test('moving back to the root keeps the edited date', () async {
    final result = await repository.moveDocument('doc-1', null);

    expect(result.isRight(), isTrue);
    expect(saved?.folderId, isNull);
    expect(saved?.updatedAt, edited);
  });

  test('saving content still bumps the edited date', () async {
    final before = DateTime.now();

    final result = await repository.saveDocumentContent(
      id: 'doc-1',
      content: const {'pages': <Object>[]},
      pageCount: 1,
    );

    expect(result.isRight(), isTrue);
    expect(saved?.updatedAt.isBefore(before), isFalse);
  });

  test('renaming still bumps the edited date', () async {
    final before = DateTime.now();

    await repository.saveDocumentContent(
      id: 'doc-1',
      content: const {'title': 'New notes'},
      title: 'New notes',
    );

    expect(saved?.title, 'New notes');
    expect(saved?.updatedAt.isBefore(before), isFalse);
  });
}
