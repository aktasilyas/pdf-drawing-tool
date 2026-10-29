import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

DocumentInfo _info(String id, String title, {int pages = 1, int day = 1}) =>
    DocumentInfo(
      id: id,
      title: title,
      templateId: 'blank',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, day),
      pageCount: pages,
    );

/// Leaving the editor must refresh the library lists (#464): they are
/// non-autoDispose FutureProviders that only change on invalidation.
void main() {
  late _MockDocumentRepository repo;
  late ProviderContainer container;
  late List<DocumentInfo> stored;

  setUp(() {
    repo = _MockDocumentRepository();
    stored = [_info('a', 'Old', day: 1), _info('b', 'Other', day: 2)];
    List<DocumentInfo> byDateDesc() =>
        [...stored]..sort((x, y) => y.updatedAt.compareTo(x.updatedAt));
    List<DocumentInfo> favorites() => [...stored.where((d) => d.id == 'a')];
    when(() => repo.getDocuments(folderId: null))
        .thenAnswer((_) async => Right(List.of(stored)));
    when(() => repo.getRecent(limit: 10))
        .thenAnswer((_) async => Right(byDateDesc()));
    when(() => repo.getFavorites())
        .thenAnswer((_) async => Right(favorites()));
    container = ProviderContainer(overrides: [
      documentRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  /// Simulates the editor's save of notebook `a` before leaving.
  void saveEditedNotebook() {
    stored = [_info('a', 'New', pages: 3, day: 5), stored[1]];
  }

  test('documents list shows the saved title, page count and date', () async {
    final before = await container.read(documentsProvider(null).future);
    expect(before.first.title, 'Old');

    saveEditedNotebook();
    closeEditorSession(container.read, container.invalidate);

    final after = await container.read(documentsProvider(null).future);
    final a = after.firstWhere((d) => d.id == 'a');
    expect(a.title, 'New');
    expect(a.pageCount, 3);
    expect(a.updatedAt, DateTime(2026, 1, 5));
  });

  test('recent lists the edited notebook first', () async {
    final before = await container.read(recentDocumentsProvider.future);
    expect(before.first.id, 'b');

    saveEditedNotebook();
    closeEditorSession(container.read, container.invalidate);

    final after = await container.read(recentDocumentsProvider.future);
    expect(after.first.id, 'a');
    expect(after.first.title, 'New');
  });

  test('favorites show the saved title', () async {
    final before = await container.read(favoriteDocumentsProvider.future);
    expect(before.single.title, 'Old');

    saveEditedNotebook();
    closeEditorSession(container.read, container.invalidate);

    final after = await container.read(favoriteDocumentsProvider.future);
    expect(after.single.title, 'New');
  });
}
