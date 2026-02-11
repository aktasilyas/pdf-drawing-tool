import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/widgets/document_list_tile.dart';

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
  });
}
