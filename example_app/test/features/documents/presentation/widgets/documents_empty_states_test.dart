import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_empty_states.dart';

void main() {
  group('DocumentsEmptyState', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentsEmptyState(),
          ),
        ),
      );

      expect(find.byType(DocumentsEmptyState), findsOneWidget);
      expect(find.text('Henüz not yok'), findsOneWidget);
      expect(
        find.text('Yeni bir not oluşturmak için "+" butonuna tıklayın'),
        findsOneWidget,
      );
    });
  });

  group('FavoritesEmptyState', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FavoritesEmptyState(),
          ),
        ),
      );

      expect(find.byType(FavoritesEmptyState), findsOneWidget);
      expect(find.text('Favori not yok'), findsOneWidget);
    });
  });

  group('FolderEmptyState', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FolderEmptyState(),
          ),
        ),
      );

      expect(find.byType(FolderEmptyState), findsOneWidget);
      expect(find.text('Bu klasör boş'), findsOneWidget);
    });
  });

  group('TrashEmptyState', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrashEmptyState(),
          ),
        ),
      );

      expect(find.byType(TrashEmptyState), findsOneWidget);
      expect(find.text('Çöp kutusu boş'), findsOneWidget);
    });
  });

  group('DocumentsEmptySearchResult', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsEmptySearchResult(query: 'test'),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentsEmptySearchResult), findsOneWidget);
      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
    });
  });

  group('DocumentsComingSoon', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentsComingSoon(),
          ),
        ),
      );

      expect(find.byType(DocumentsComingSoon), findsOneWidget);
      expect(find.text('Yakında'), findsOneWidget);
    });
  });
}
