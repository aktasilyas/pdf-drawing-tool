import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart';

void main() {
  group('DocumentsHeader', () {
    testWidgets('should_render_without_error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsHeader(
                title: 'Test Title',
                onNewPressed: () {},
                sortOption: SortOption.date,
                onSortChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DocumentsHeader), findsOneWidget);
    });

    testWidgets('should_display_title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsHeader(
                title: 'My Documents',
                onNewPressed: () {},
                sortOption: SortOption.date,
                onSortChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Documents'), findsOneWidget);
    });

    testWidgets('should_render_new_button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsHeader(
                title: 'Documents',
                onNewPressed: () {},
                sortOption: SortOption.date,
                onSortChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // New button should be visible
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should_call_onNewPressed_when_tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsHeader(
                title: 'Documents',
                onNewPressed: () => pressed = true,
                sortOption: SortOption.date,
                onSortChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('should_display_sort_button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsHeader(
                title: 'Documents',
                onNewPressed: () {},
                sortOption: SortOption.date,
                onSortChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Sort button should be visible
      expect(find.byIcon(Icons.sort), findsOneWidget);
    });
  });
}
