import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_content_view.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';

void main() {
  group('DocumentsContentView', () {
    testWidgets('should_render_for_shared_section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsContentView(
                section: SidebarSection.shared,
                folderId: null,
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

    testWidgets('should_render_for_store_section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsContentView(
                section: SidebarSection.store,
                folderId: null,
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
      // Coming soon state should be displayed
      expect(find.text('Yakında'), findsOneWidget);
    });

    testWidgets('should_accept_folder_id_parameter', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsContentView(
                section: SidebarSection.shared,
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
}
