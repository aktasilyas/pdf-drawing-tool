import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/document_list_tile.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_list_view.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_list_tile.dart';

void main() {
  group('DocumentsCombinedListView', () {
    testWidgets('should_render_empty_list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentsCombinedListView(
                folders: const [],
                documents: const [],
                onFolderTap: (_) {},
                onDocumentTap: (_) {},
                onFolderMore: (_) {},
                onDocumentMore: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentsCombinedListView), findsOneWidget);
    });

    testWidgets('should_render_with_folders', (tester) async {
      final folder = Folder(
        id: 'folder-1',
        name: 'Test Folder',
        colorValue: Colors.blue.value,
        createdAt: DateTime(2025, 1, 1),
        documentCount: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentsCombinedListView(
                folders: [folder],
                documents: const [],
                onFolderTap: (_) {},
                onDocumentTap: (_) {},
                onFolderMore: (_) {},
                onDocumentMore: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentsCombinedListView), findsOneWidget);
      expect(find.text('Test Folder'), findsOneWidget);
    });

    testWidgets('should_render_with_documents', (tester) async {
      final document = DocumentInfo(
        id: 'doc-1',
        title: 'Test Document',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        templateId: 'template-1',
        isFavorite: false,
        folderId: null,
        thumbnailPath: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentsCombinedListView(
                folders: const [],
                documents: [document],
                onFolderTap: (_) {},
                onDocumentTap: (_) {},
                onFolderMore: (_) {},
                onDocumentMore: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentsCombinedListView), findsOneWidget);
      expect(find.text('Test Document'), findsOneWidget);
    });

    testWidgets('should_display_folder_name', (tester) async {
      final folder = Folder(
        id: 'folder-1',
        name: 'My Folder',
        colorValue: Colors.green.value,
        createdAt: DateTime(2025, 1, 1),
        documentCount: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentsCombinedListView(
                folders: [folder],
                documents: const [],
                onFolderTap: (_) {},
                onDocumentTap: (_) {},
                onFolderMore: (_) {},
                onDocumentMore: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Folder'), findsOneWidget);
    });

    testWidgets('should_display_document_title', (tester) async {
      final document = DocumentInfo(
        id: 'doc-1',
        title: 'My Document',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        templateId: 'template-1',
        isFavorite: false,
        folderId: null,
        thumbnailPath: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentsCombinedListView(
                folders: const [],
                documents: [document],
                onFolderTap: (_) {},
                onDocumentTap: (_) {},
                onFolderMore: (_) {},
                onDocumentMore: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Document'), findsOneWidget);
    });

    testWidgets('folder and document rows are both 64 high', (tester) async {
      final folder = Folder(
        id: 'folder-1',
        name: 'Folder',
        colorValue: Colors.green.value,
        createdAt: DateTime(2025, 1, 1),
        documentCount: 3,
      );
      final document = DocumentInfo(
        id: 'doc-1',
        title: 'Doc',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        templateId: 'template-1',
        isFavorite: false,
        folderId: null,
        thumbnailPath: null,
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentsCombinedListView(
                folders: [folder],
                documents: [document],
                onFolderTap: (_) {},
                onDocumentTap: (_) {},
                onFolderMore: (_) {},
                onDocumentMore: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FolderListTile)).height, 64);
      expect(tester.getSize(find.byType(DocumentListTile)).height, 64);
      expect(find.text('3 belge'), findsOneWidget);
    });
  });
}
