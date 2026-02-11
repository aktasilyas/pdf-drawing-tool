import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';

void main() {
  group('DocumentsErrorView', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentsErrorView(error: 'Test error'),
          ),
        ),
      );

      expect(find.byType(DocumentsErrorView), findsOneWidget);
      expect(find.text('Hata: Test error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should_display_error_icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentsErrorView(error: 'Network error'),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, equals(48));
    });
  });

  group('DocumentsEmptyFolderView', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentsEmptyFolderView(),
          ),
        ),
      );

      expect(find.byType(DocumentsEmptyFolderView), findsOneWidget);
      expect(find.text('Bu klasör boş'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('should_display_folder_icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentsEmptyFolderView(),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.folder_open));
      expect(icon.size, equals(64));
    });
  });
}
