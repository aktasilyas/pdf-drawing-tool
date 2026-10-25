import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_list_tile.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';

void main() {
  group('DocumentListTile', () {
    late DocumentInfo testDocument;

    setUp(() {
      testDocument = DocumentInfo(
        id: 'test-id',
        title: 'Test Document',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        templateId: 'template-1',
        isFavorite: false,
        folderId: null,
        thumbnailPath: null,
      );
    });

    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentListTile(
                document: testDocument,
                onTap: () {},
                onLongPress: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentListTile), findsOneWidget);
      expect(find.text('Test Document'), findsOneWidget);
    });

    testWidgets('should_display_document_name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentListTile(
                document: testDocument,
                onTap: () {},
                onLongPress: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Document'), findsOneWidget);
    });

    testWidgets('should_respond_to_tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentListTile(
                document: testDocument,
                onTap: () => tapped = true,
                onLongPress: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DocumentListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should_respond_to_long_press', (tester) async {
      var longPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentListTile(
                document: testDocument,
                onTap: () {},
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(DocumentListTile));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    Future<void> pumpTile(
      WidgetTester tester, {
      bool selection = false,
      DocumentInfo? document,
    }) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            if (selection) selectionModeProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentListTile(
                document: document ?? testDocument,
                onTap: () {},
                onLongPress: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('row is 64 high', (tester) async {
      await pumpTile(tester);
      expect(tester.getSize(find.byType(DocumentListTile)).height, 64);
    });

    testWidgets('shows a caret and no checkbox outside selection mode',
        (tester) async {
      await pumpTile(tester);
      expect(find.byIcon(ElyanotesIcons.libraryCaretRight), findsOneWidget);
      expect(find.byType(LibrarySelectionCheckbox), findsNothing);
    });

    testWidgets('selection mode shows the checkbox and hides the caret',
        (tester) async {
      await pumpTile(tester, selection: true);
      expect(find.byType(LibrarySelectionCheckbox), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.libraryCaretRight), findsNothing);
    });

    testWidgets('favorite shows a filled star', (tester) async {
      await pumpTile(tester, document: testDocument.copyWith(isFavorite: true));
      expect(find.byIcon(ElyanotesIcons.libraryStarFill), findsOneWidget);
    });
  });
}
