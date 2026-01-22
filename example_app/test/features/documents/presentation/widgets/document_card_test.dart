import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';

void main() {
  group('DocumentCard', () {
    final testDocument = DocumentInfo(
      id: 'doc-1',
      title: 'Test Document',
      templateId: 'blank',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      pageCount: 5,
      isFavorite: false,
    );

    Widget createTestWidget(DocumentInfo document) {
      return MaterialApp(
        home: Scaffold(
          body: DocumentCard(
            document: document,
          ),
        ),
      );
    }

    testWidgets('should display document title', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(testDocument));

      // Assert
      expect(find.text('Test Document'), findsOneWidget);
    });

    testWidgets('should display page count', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(testDocument));

      // Assert
      expect(find.textContaining('5 sayfa'), findsOneWidget);
    });

    testWidgets('should show favorite icon when favorited', (tester) async {
      // Arrange
      final favDocument = testDocument.copyWith(isFavorite: true);
      await tester.pumpWidget(createTestWidget(favDocument));

      // Assert
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should show favorite_border icon when not favorited',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(testDocument));

      // Assert
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      // Arrange
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCard(
              document: testDocument,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(DocumentCard));
      await tester.pump();

      // Assert
      expect(tapped, true);
    });

    testWidgets('should call onFavoriteToggle when favorite icon is tapped',
        (tester) async {
      // Arrange
      bool favoriteToggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCard(
              document: testDocument,
              onFavoriteToggle: () => favoriteToggled = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      // Assert
      expect(favoriteToggled, true);
    });

    testWidgets('should call onMorePressed when more button is tapped',
        (tester) async {
      // Arrange
      bool morePressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCard(
              document: testDocument,
              onMorePressed: () => morePressed = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();

      // Assert
      expect(morePressed, true);
    });
  });
}
