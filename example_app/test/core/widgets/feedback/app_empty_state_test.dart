import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/feedback/app_empty_state.dart';

void main() {
  group('AppEmptyState', () {
    Widget buildTestWidget({
      required Widget child,
      bool isDark = false,
    }) {
      return MaterialApp(
        theme: isDark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: child),
      );
    }

    group('Light Theme', () {
      testWidgets('should_use_textSecondaryLight_for_icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Test Title',
            ),
            isDark: false,
          ),
        );

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
        expect(icon.color, equals(AppColors.textSecondaryLight));
      });

      testWidgets('should_use_textPrimaryLight_for_title', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Test Title',
            ),
            isDark: false,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('Test Title'));
        expect(text.style?.color, equals(AppColors.textPrimaryLight));
      });

      testWidgets('should_use_textSecondaryLight_for_description', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Test Title',
              description: 'Test Description',
            ),
            isDark: false,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('Test Description'));
        expect(text.style?.color, equals(AppColors.textSecondaryLight));
      });

      testWidgets('should_display_all_parameters', (tester) async {
        // Arrange
        bool actionPressed = false;
        await tester.pumpWidget(
          buildTestWidget(
            child: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Documents',
              description: 'Start by creating a new document',
              actionLabel: 'New Document',
              onAction: () => actionPressed = true,
            ),
            isDark: false,
          ),
        );

        // Assert
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        expect(find.text('No Documents'), findsOneWidget);
        expect(find.text('Start by creating a new document'), findsOneWidget);
        expect(find.text('New Document'), findsOneWidget);

        // Test action button
        await tester.tap(find.text('New Document'));
        await tester.pump();
        expect(actionPressed, true);
      });

      testWidgets('should_work_with_minimal_parameters', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Empty State',
            ),
            isDark: false,
          ),
        );

        // Assert
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        expect(find.text('Empty State'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      });
    });

    group('Dark Theme', () {
      testWidgets('should_use_textSecondaryDark_for_icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Test Title',
            ),
            isDark: true,
          ),
        );

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
        expect(icon.color, equals(AppColors.textSecondaryDark));
      });

      testWidgets('should_use_textPrimaryDark_for_title', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Test Title',
            ),
            isDark: true,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('Test Title'));
        expect(text.style?.color, equals(AppColors.textPrimaryDark));
      });

      testWidgets('should_use_textSecondaryDark_for_description', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Test Title',
              description: 'Test Description',
            ),
            isDark: true,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('Test Description'));
        expect(text.style?.color, equals(AppColors.textSecondaryDark));
      });

      testWidgets('should_display_all_parameters', (tester) async {
        // Arrange
        bool actionPressed = false;
        await tester.pumpWidget(
          buildTestWidget(
            child: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Documents',
              description: 'Start by creating a new document',
              actionLabel: 'New Document',
              onAction: () => actionPressed = true,
            ),
            isDark: true,
          ),
        );

        // Assert
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        expect(find.text('No Documents'), findsOneWidget);
        expect(find.text('Start by creating a new document'), findsOneWidget);
        expect(find.text('New Document'), findsOneWidget);

        // Test action button
        await tester.tap(find.text('New Document'));
        await tester.pump();
        expect(actionPressed, true);
      });

      testWidgets('should_work_with_minimal_parameters', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Empty State',
            ),
            isDark: true,
          ),
        );

        // Assert
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        expect(find.text('Empty State'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      });
    });

    group('Layout', () {
      testWidgets('should_render_icon_above_title', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Test Title',
            ),
          ),
        );

        // Assert
        final iconFinder = find.byIcon(Icons.inbox_outlined);
        final titleFinder = find.text('Test Title');

        expect(iconFinder, findsOneWidget);
        expect(titleFinder, findsOneWidget);

        // Icon should be above title
        final iconY = tester.getCenter(iconFinder).dy;
        final titleY = tester.getCenter(titleFinder).dy;
        expect(iconY, lessThan(titleY));
      });

      testWidgets('should_center_all_content', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Test Title',
              description: 'Test Description',
            ),
          ),
        );

        // Assert
        expect(find.byType(Center), findsWidgets);
        expect(find.byType(Column), findsOneWidget);
      });
    });
  });
}
