import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';

void main() {
  group('DocumentsErrorView', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
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
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: DocumentsErrorView(error: 'Network error'),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, equals(48));
    });

    testWidgets('should_hide_retry_button_without_onRetry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: DocumentsErrorView(error: 'Test error'),
          ),
        ),
      );

      expect(find.text('Tekrar dene'), findsNothing);
    });

    testWidgets('should_call_onRetry_when_retry_tapped', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsErrorView(
              error: 'Test error',
              onRetry: () => retried++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tekrar dene'));
      await tester.pump();

      expect(retried, equals(1));
    });

    testWidgets('should_keep_retry_button_at_least_48dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsErrorView(error: 'Test error', onRetry: () {}),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('DocumentsEmptyFolderView', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
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
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: DocumentsEmptyFolderView(),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.folder_open));
      expect(icon.size, equals(64));
    });
  });
}
