import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/presentation/widgets/library_grid_metrics.dart';

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

    Widget host(Widget body) {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: body),
        ),
      );
    }

    Widget createTestWidget(DocumentInfo document) {
      return host(DocumentCard(document: document, onTap: () {}));
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

    testWidgets('should show star icon when favorited', (tester) async {
      // Arrange
      final favDocument = testDocument.copyWith(isFavorite: true);
      await tester.pumpWidget(createTestWidget(favDocument));

      // Assert
      expect(find.byIcon(ElyanotesIcons.libraryStarFill), findsOneWidget);
    });

    testWidgets('should show no favorite badge when not favorited',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(testDocument));

      // Assert
      expect(find.byIcon(ElyanotesIcons.libraryStarFill), findsNothing);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      // Arrange
      bool tapped = false;
      await tester.pumpWidget(
        host(DocumentCard(
          document: testDocument,
          onTap: () => tapped = true,
        )),
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
        host(DocumentCard(
          document: testDocument.copyWith(isFavorite: true),
          onTap: () {},
          onFavoriteToggle: () => favoriteToggled = true,
        )),
      );

      // Act
      await tester.tap(find.byIcon(ElyanotesIcons.libraryStarFill));
      await tester.pump();

      // Assert
      expect(favoriteToggled, true);
    });

    testWidgets('should call onMorePressed when more button is tapped',
        (tester) async {
      // Arrange
      bool morePressed = false;
      await tester.pumpWidget(
        host(DocumentCard(
          document: testDocument,
          onTap: () {},
          onMorePressed: () => morePressed = true,
        )),
      );

      // Act
      await tester.tap(find.byIcon(ElyanotesIcons.libraryCaretDown));
      await tester.pump();

      // Assert
      expect(morePressed, true);
    });

    testWidgets('long press outside selection mode enters selection',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DocumentCard(document: testDocument, onTap: () {}),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(DocumentCard));
      await tester.pump();

      expect(container.read(selectionModeProvider), isTrue);
      expect(container.read(selectedDocumentsProvider), {'doc-1'});
    });

    testWidgets('caret is hidden in selection mode', (tester) async {
      await tester.pumpWidget(
        host(DocumentCard(
          document: testDocument,
          onTap: () {},
          onMorePressed: () {},
          isSelectionMode: true,
        )),
      );

      expect(find.byIcon(ElyanotesIcons.libraryCaretDown), findsNothing);
    });

    testWidgets('should ellipsize a long title on one line', (tester) async {
      final longDoc = testDocument.copyWith(
        title: 'Çok uzun bir defter adı kısaltma testi için',
      );
      await tester.pumpWidget(createTestWidget(longDoc));

      final text = tester.widget<Text>(find.text(longDoc.title));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should not overflow at text scale 1.3 in a metrics grid',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const scaler = TextScaler.linear(1.3);
      final metrics = LibraryGridMetrics.resolve(
        availableWidth: 1000 - 48,
        isPhone: false,
        textScaler: scaler,
      );
      final docs = [
        for (var i = 0; i < 8; i++)
          testDocument.copyWith(
            id: 'doc-$i',
            title: i == 4
                ? 'Çok uzun bir defter adı kısaltma testi için'
                : 'Defter $i',
            pageCount: 24,
          ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: scaler),
              child: child!,
            ),
            home: Scaffold(
              body: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.xl),
                gridDelegate: metrics.delegate,
                itemCount: docs.length,
                itemBuilder: (context, i) => DocumentCard(
                  document: docs[i],
                  onTap: () {},
                  onMorePressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
