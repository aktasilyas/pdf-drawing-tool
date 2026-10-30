import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/documents.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  DocumentInfo doc(String id, String title) => DocumentInfo(
        id: id,
        title: title,
        templateId: 'blank',
        createdAt: now,
        updatedAt: now,
      );
  Folder folder(String id, String name, {String? parentId}) =>
      Folder(id: id, name: name, parentId: parentId, createdAt: now);

  Future<(List<String>, List<String>)> ids(
    WidgetTester tester,
    SidebarSection section,
    String query,
  ) async {
    late List<String> docIds;
    late List<String> folderIds;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchQueryProvider.overrideWith((ref) => query),
          foldersProvider.overrideWith((ref) async =>
              [folder('f1', 'Fizik'), folder('f2', 'Lab', parentId: 'f1')]),
          documentsProvider.overrideWith((ref, id) async => [doc('r', 'Root')]),
          searchResultsProvider
              .overrideWith((ref) async => [doc('s', 'Fizik notlari')]),
          favoriteDocumentsProvider.overrideWith(
              (ref) async => [doc('a', 'Fizik'), doc('b', 'Kimya')]),
          favoriteFoldersProvider
              .overrideWith((ref) async => [folder('f1', 'Fizik')]),
        ],
        child: Consumer(builder: (context, ref, _) {
          docIds = getCurrentDocumentIds(ref, section, null);
          folderIds = getCurrentFolderIds(ref, section, null);
          return const SizedBox();
        }),
      ),
    );
    await tester.pump();
    await tester.pump();
    return (docIds, folderIds);
  }

  testWidgets('documents search selects library-wide results', (tester) async {
    final (d, f) = await ids(tester, SidebarSection.documents, 'fiz');
    expect(d, ['s']);
    expect(f, ['f1']);
  });

  testWidgets('favorites search selects only matching favorites',
      (tester) async {
    final (d, f) = await ids(tester, SidebarSection.favorites, 'fiz');
    expect(d, ['a']);
    expect(f, ['f1']);
  });

  testWidgets('favorites with unmatched query selects nothing', (tester) async {
    final (d, f) = await ids(tester, SidebarSection.favorites, 'xyz');
    expect(d, isEmpty);
    expect(f, isEmpty);
  });
}
