import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart';
import 'package:example_app/features/documents/presentation/widgets/selection_mode_header.dart';
import '../../../../helpers/l10n.dart';

void main() {
  group('DocumentsHeader', () {
    Widget buildSubject({
      VoidCallback? onNewPressed,
      SortOption sortOption = SortOption.date,
      ValueChanged<SortOption>? onSortChanged,
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: overrides,
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsHeader(
              title: 'Tüm Notlar',
              onNewPressed: onNewPressed ?? () {},
              sortOption: sortOption,
              onSortChanged: onSortChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    void setSize(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('should render without error', (tester) async {
      setSize(tester, const Size(1000, 800));
      await tester.pumpWidget(buildSubject());
      expect(find.byType(DocumentsHeader), findsOneWidget);
      expect(find.text('Tüm Notlar'), findsOneWidget);
    });

    testWidgets('should render new button', (tester) async {
      setSize(tester, const Size(1000, 800));
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(ElyanotesIcons.libraryPlus), findsOneWidget);
    });

    testWidgets('should call onNewPressed when tapped', (tester) async {
      setSize(tester, const Size(1000, 800));
      var pressed = false;
      await tester.pumpWidget(
        buildSubject(onNewPressed: () => pressed = true),
      );

      await tester.tap(find.byIcon(ElyanotesIcons.libraryPlus));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('wide pane shows one search field and one AppButton',
        (tester) async {
      setSize(tester, const Size(800, 800));
      await tester.pumpWidget(buildSubject());
      expect(find.byType(AppSearchField), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('compact pane uses an icon button instead of AppButton',
        (tester) async {
      setSize(tester, const Size(600, 800));
      await tester.pumpWidget(buildSubject());
      expect(find.byType(AppButton), findsNothing);
      expect(find.byType(AppSearchField), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.libraryPlus), findsOneWidget);
    });

    testWidgets('typing in search writes searchQueryProvider after debounce',
        (tester) async {
      setSize(tester, const Size(800, 800));
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'bio');
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
          tester.element(find.byType(DocumentsHeader)));
      expect(container.read(searchQueryProvider), 'bio');
    });

    testWidgets('selection mode shows SelectionModeHeader and no search',
        (tester) async {
      setSize(tester, const Size(800, 800));
      await tester.pumpWidget(
        buildSubject(
          overrides: [selectionModeProvider.overrideWith((ref) => true)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SelectionModeHeader), findsOneWidget);
      expect(find.byType(AppSearchField), findsNothing);
    });
  });
}
