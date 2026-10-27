import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_empty_states.dart';
import '../../../../helpers/l10n.dart';

void main() {
  group('DocumentsEmptyState', () {
    Future<void> pump(WidgetTester tester, {VoidCallback? onCreateNew}) {
      return tester.pumpWidget(
        localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsEmptyState(onCreateNew: onCreateNew),
          ),
        ),
      );
    }

    testWidgets('should_render_without_error', (tester) async {
      await pump(tester);

      expect(find.byType(DocumentsEmptyState), findsOneWidget);
      expect(find.text('Henüz not yok'), findsOneWidget);
      expect(
        find.text('Yeni bir defter oluşturun ya da bir PDF içe aktarın.'),
        findsOneWidget,
      );
    });

    testWidgets('Yeni not button has a 48dp hit height', (tester) async {
      await pump(tester, onCreateNew: () {});
      final size = tester.getSize(find.byType(AppButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('Yeni not button calls onCreateNew', (tester) async {
      var called = false;
      await pump(tester, onCreateNew: () => called = true);

      await tester.tap(find.text('Yeni not'));
      expect(called, isTrue);
    });

    testWidgets('no button without onCreateNew', (tester) async {
      await pump(tester);
      expect(find.text('Yeni not'), findsNothing);
      expect(find.byType(AppButton), findsNothing);
    });
  });

  group('FavoritesEmptyState', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          theme: AppTheme.light,
          home: const Scaffold(
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
        localizedApp(
          theme: AppTheme.light,
          home: const Scaffold(
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
        localizedApp(
          theme: AppTheme.light,
          home: const Scaffold(
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
          child: localizedApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: DocumentsEmptySearchResult(query: 'test'),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentsEmptySearchResult), findsOneWidget);
      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.librarySearch), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.libraryClose), findsOneWidget);
    });
  });
}
