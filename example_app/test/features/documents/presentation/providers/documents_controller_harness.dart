import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/premium/premium.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

class MockPageTrashRepository extends Mock implements PageTrashRepository {}

const failure = CacheFailure('boom');

final testDocument = DocumentInfo(
  id: 'doc-1',
  title: 'Notes',
  templateId: 'blank',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 2),
);

/// Provider names reported by [DocumentsHarness.rebuiltBy].
const allLists = {
  'documents',
  'favorites',
  'recent',
  'trash',
  'folders',
  'totalCount',
  'notebookCount',
};
const trashMoveLists = {'documents', 'trash', 'folders'};
const permanentDeleteLists = {'trash', 'totalCount', 'notebookCount'};
const pageTrashLists = {'trashedPages', 'trashItems'};

void registerDocumentsFallbacks() {
  registerFallbackValue(DocumentType.notebook);
  registerFallbackValue(<String, dynamic>{});
  registerFallbackValue(DateTime(2026));
}

/// A [ProviderContainer] with mocked repositories that counts how often each
/// list provider is built, so tests can assert which ones were invalidated.
class DocumentsHarness {
  final repo = MockDocumentRepository();
  final pageTrash = MockPageTrashRepository();
  final builds = <String, int>{};
  late final ProviderContainer container;

  DocumentsHarness() {
    when(() => repo.getDocuments(folderId: null)).thenAnswer((_) async {
      _hit('documents');
      return const Right([]);
    });
    when(() => repo.getFavorites()).thenAnswer((_) async {
      _hit('favorites');
      return const Right([]);
    });
    when(() => repo.getRecent(limit: 10)).thenAnswer((_) async {
      _hit('recent');
      return const Right([]);
    });
    when(() => repo.getTrash()).thenAnswer((_) async {
      _hit('trash');
      return const Right([]);
    });
    when(() => pageTrash.getTrashedPages()).thenAnswer((_) async {
      _hit('trashedPages');
      return [];
    });
    container = ProviderContainer(overrides: [
      documentRepositoryProvider.overrideWithValue(repo),
      pageTrashRepositoryProvider.overrideWithValue(pageTrash),
      foldersProvider.overrideWith((ref) async {
        _hit('folders');
        return [];
      }),
      totalDocumentCountProvider.overrideWith((ref) async {
        _hit('totalCount');
        return 0;
      }),
      notebookCountProvider.overrideWith((ref) async {
        _hit('notebookCount');
        return 0;
      }),
      trashItemsProvider.overrideWith((ref) async {
        _hit('trashItems');
        return [];
      }),
    ]);
  }

  DocumentsController get controller =>
      container.read(documentsControllerProvider.notifier);

  AsyncValue<void> get state => container.read(documentsControllerProvider);

  void _hit(String name) => builds[name] = (builds[name] ?? 0) + 1;

  Future<void> _readAll() async {
    await container.read(documentsProvider(null).future);
    await container.read(favoriteDocumentsProvider.future);
    await container.read(recentDocumentsProvider.future);
    await container.read(trashDocumentsProvider.future);
    await container.read(foldersProvider.future);
    await container.read(totalDocumentCountProvider.future);
    await container.read(notebookCountProvider.future);
    await container.read(trashedPagesProvider.future);
    await container.read(trashItemsProvider.future);
  }

  /// Runs [action] and returns the names of the providers it invalidated.
  Future<Set<String>> rebuiltBy(Future<void> Function() action) async {
    await _readAll();
    final before = Map.of(builds);
    await action();
    await _readAll();
    return builds.keys.where((k) => builds[k] != before[k]).toSet();
  }

  void dispose() => container.dispose();
}
