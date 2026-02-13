import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_combined_grid.dart';

void main() {
  group('DocumentsCombinedGridView', () {
    testWidgets('should_render_empty_grid', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsCombinedGridView(
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

      expect(find.byType(DocumentsCombinedGridView), findsOneWidget);
    });

    testWidgets('should_render_with_folders', (tester) async {
      final folder = Folder(
        id: 'folder-1',
        name: 'Test Folder',
        colorValue: Colors.blue.value,
        createdAt: DateTime(2025, 1, 1),
        documentCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsCombinedGridView(
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

      expect(find.byType(DocumentsCombinedGridView), findsOneWidget);
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
            home: Scaffold(
              body: DocumentsCombinedGridView(
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

      expect(find.byType(DocumentsCombinedGridView), findsOneWidget);
    });

    testWidgets('should_render_with_both_folders_and_documents', (tester) async {
      final folder = Folder(
        id: 'folder-1',
        name: 'Test Folder',
        colorValue: Colors.blue.value,
        createdAt: DateTime(2025, 1, 1),
        documentCount: 0,
      );

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
            home: Scaffold(
              body: DocumentsCombinedGridView(
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

      expect(find.byType(DocumentsCombinedGridView), findsOneWidget);
    });
  });
}
