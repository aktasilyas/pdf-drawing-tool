import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';
import 'package:example_app/l10n/l10n.dart';
import '../../../../helpers/l10n.dart';

void main() {
  final l10n = lookupAppLocalizations(testLocale);

  group('DocumentsErrorView', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: DocumentsErrorView(error: 'Test error'),
          ),
        ),
      );

      expect(find.byType(DocumentsErrorView), findsOneWidget);
      expect(find.text(l10n.libraryLoadFailed), findsOneWidget);
      expect(find.textContaining('Test error'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('never_shows_exception_text_and_offers_retry (#405)',
        (tester) async {
      await tester.pumpWidget(
        localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsErrorView(
              error: 'Exception: boom',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text(l10n.libraryLoadFailed), findsOneWidget);
      expect(find.textContaining('boom'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.byKey(DocumentsErrorView.retryKey), findsOneWidget);
      expect(find.text(l10n.commonRetry), findsOneWidget);
    });

    testWidgets('shows_the_given_message_instead_of_the_default',
        (tester) async {
      await tester.pumpWidget(
        localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsErrorView(
              error: StateError('boom'),
              message: l10n.libraryTrashLoadFailed,
            ),
          ),
        ),
      );

      expect(find.text(l10n.libraryTrashLoadFailed), findsOneWidget);
      expect(find.text(l10n.libraryLoadFailed), findsNothing);
      expect(find.textContaining('boom'), findsNothing);
    });

    testWidgets('should_display_error_icon', (tester) async {
      await tester.pumpWidget(
        localizedApp(
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
        localizedApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: DocumentsErrorView(error: 'Test error'),
          ),
        ),
      );

      expect(find.byKey(DocumentsErrorView.retryKey), findsNothing);
    });

    testWidgets('should_call_onRetry_when_retry_tapped', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsErrorView(
              error: 'Test error',
              onRetry: () => retried++,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentsErrorView.retryKey));
      await tester.pump();

      expect(retried, equals(1));
    });

    testWidgets('should_keep_retry_button_at_least_48dp', (tester) async {
      await tester.pumpWidget(
        localizedApp(
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
        localizedApp(
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
        localizedApp(
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
