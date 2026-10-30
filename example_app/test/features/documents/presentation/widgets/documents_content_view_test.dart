import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_content_view.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_empty_states.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import '../../../../helpers/l10n.dart';

void main() {
  group('DocumentsContentView', () {
    testWidgets('should_accept_folder_id_parameter', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: localizedApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentsContentView(
                section: SidebarSection.folder,
                folderId: 'test-folder-id',
                onFolderTap: (_) {},
                onDocumentTap: (_) {},
                onFolderMore: (_) {},
                onDocumentMore: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentsContentView), findsOneWidget);
    });

    testWidgets('should_call_callbacks_when_provided', (tester) async {
      var folderTapped = false;
      var documentTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: localizedApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentsContentView(
                section: SidebarSection.folder,
                folderId: null,
                onFolderTap: (_) => folderTapped = true,
                onDocumentTap: (_) => documentTapped = true,
                onFolderMore: (_) {},
                onDocumentMore: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentsContentView), findsOneWidget);
      // Callbacks are provided and ready to use
      expect(folderTapped, isFalse);
      expect(documentTapped, isFalse);
    });
  });

  group('DocumentsContentView favorites', () {
    Widget buildFavorites(List<Override> overrides) {
      return ProviderScope(
        overrides: overrides,
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsContentView(
              section: SidebarSection.favorites,
              folderId: null,
              onFolderTap: (_) {},
              onDocumentTap: (_) {},
              onFolderMore: (_) {},
              onDocumentMore: (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('should_show_favorites_empty_state_when_no_favorites',
        (tester) async {
      await tester.pumpWidget(
        buildFavorites([
          favoriteFoldersProvider.overrideWith((ref) async => <Folder>[]),
          favoriteDocumentsProvider
              .overrideWith((ref) async => <DocumentInfo>[]),
        ]),
      );
      await tester.pump();

      expect(find.byType(FavoritesEmptyState), findsOneWidget);
      expect(find.byType(DocumentsEmptyState), findsNothing);
    });

    testWidgets('should_retry_favorite_folders_when_retry_tapped',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        buildFavorites([
          favoriteFoldersProvider.overrideWith((ref) async {
            calls++;
            throw Exception('boom');
          }),
          favoriteDocumentsProvider
              .overrideWith((ref) async => <DocumentInfo>[]),
        ]),
      );
      await tester.pump();

      expect(find.byType(DocumentsErrorView), findsOneWidget);
      expect(calls, equals(1));

      await tester.tap(find.text('Tekrar dene'));
      await tester.pump();
      await tester.pump();

      expect(calls, equals(2));
    });
  });

  group('DocumentsContentView search', () {
    final now = DateTime(2026, 1, 1);
    DocumentInfo doc(String id, String title) => DocumentInfo(
          id: id,
          title: title,
          templateId: 'blank',
          createdAt: now,
          updatedAt: now,
        );

    Widget build(SidebarSection section, List<Override> overrides) {
      return ProviderScope(
        overrides: overrides,
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsContentView(
              section: section,
              folderId: null,
              onFolderTap: (_) {},
              onDocumentTap: (_) {},
              onFolderMore: (_) {},
              onDocumentMore: (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('should_find_notebook_in_subfolder_when_searching_documents',
        (tester) async {
      await tester.pumpWidget(
        build(SidebarSection.documents, [
          searchQueryProvider.overrideWith((ref) => 'fiz'),
          foldersProvider.overrideWith((ref) async => <Folder>[]),
          documentsProvider.overrideWith((ref, id) async => <DocumentInfo>[]),
          searchResultsProvider
              .overrideWith((ref) async => [doc('1', 'Fizik')]),
        ]),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Fizik'), findsOneWidget);
      expect(find.byType(DocumentsEmptySearchResult), findsNothing);
    });

    testWidgets('should_filter_favorites_by_query', (tester) async {
      await tester.pumpWidget(
        build(SidebarSection.favorites, [
          searchQueryProvider.overrideWith((ref) => 'fiz'),
          favoriteFoldersProvider.overrideWith((ref) async => <Folder>[]),
          favoriteDocumentsProvider.overrideWith(
              (ref) async => [doc('1', 'Fizik'), doc('2', 'Kimya')]),
        ]),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Fizik'), findsOneWidget);
      expect(find.text('Kimya'), findsNothing);
    });

    testWidgets('should_show_no_results_in_favorites_for_unmatched_query',
        (tester) async {
      await tester.pumpWidget(
        build(SidebarSection.favorites, [
          searchQueryProvider.overrideWith((ref) => 'xyz'),
          favoriteFoldersProvider.overrideWith((ref) async => <Folder>[]),
          favoriteDocumentsProvider
              .overrideWith((ref) async => [doc('1', 'Fizik')]),
        ]),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(DocumentsEmptySearchResult), findsOneWidget);
    });
  });
}
