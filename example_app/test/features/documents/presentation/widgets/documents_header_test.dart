import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart';

void main() {
  group('DocumentsHeader', () {
    Widget buildSubject({
      VoidCallback? onNewPressed,
      SortOption sortOption = SortOption.date,
      ValueChanged<SortOption>? onSortChanged,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DocumentsHeader(
              onNewPressed: onNewPressed ?? () {},
              sortOption: sortOption,
              onSortChanged: onSortChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('should render without error', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(DocumentsHeader), findsOneWidget);
    });

    testWidgets('should render new button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should call onNewPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildSubject(onNewPressed: () => pressed = true),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(pressed, isTrue);
    });
  });
}
