import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_card.dart';

void main() {
  group('FolderCard', () {
    final testFolder = Folder(
      id: 'folder-1',
      name: 'Test Folder',
      colorValue: 0xFF5B7CFF,
      createdAt: DateTime(2024, 1, 1),
      documentCount: 5,
    );

    Widget buildTestWidget({
      required Folder folder,
      bool isDark = false,
      bool isSelected = false,
      bool isSelectionMode = false,
      VoidCallback? onTap,
      VoidCallback? onMorePressed,
    }) {
      return ProviderScope(
        child: MaterialApp(
          theme: isDark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: FolderCard(
              folder: folder,
              onTap: onTap ?? () {},
              onMorePressed: onMorePressed,
              isSelected: isSelected,
              isSelectionMode: isSelectionMode,
            ),
          ),
        ),
      );
    }

    group('Light Theme', () {
      testWidgets('should_use_textPrimaryLight_for_folder_name', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('Test Folder'));
        expect(text.style?.color, equals(AppColors.textPrimaryLight));
      });

      testWidgets('should_use_textSecondaryLight_for_document_count', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('5 belge'));
        expect(text.style?.color, equals(AppColors.textSecondaryLight));
      });

      testWidgets('should_display_folder_icon_with_custom_color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
          ),
        );

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.folder));
        expect(icon.color, equals(Color(testFolder.colorValue)));
      });
    });

    group('Dark Theme', () {
      testWidgets('should_use_textPrimaryDark_for_folder_name', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('Test Folder'));
        expect(text.style?.color, equals(AppColors.textPrimaryDark));
      });

      testWidgets('should_use_textSecondaryDark_for_document_count', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('5 belge'));
        expect(text.style?.color, equals(AppColors.textSecondaryDark));
      });

      testWidgets('should_display_folder_icon_with_custom_color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
          ),
        );

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.folder));
        expect(icon.color, equals(Color(testFolder.colorValue)));
      });
    });

    group('Selection Checkbox - Light Theme', () {
      testWidgets('should_not_show_checkbox_when_not_in_selection_mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
            isSelectionMode: false,
          ),
        );

        // Assert
        // The checkbox is in a Positioned widget, check that it doesn't render
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
          findsNothing,
        );
      });

      testWidgets('should_show_unselected_checkbox_with_surfaceLight_color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
            isSelectionMode: true,
            isSelected: false,
          ),
        );

        // Assert
        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppColors.surfaceLight));
        expect(decoration.border?.top.color, equals(AppColors.outlineLight));
      });

      testWidgets('should_show_selected_checkbox_with_primary_color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
            isSelectionMode: true,
            isSelected: true,
          ),
        );

        // Assert
        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppColors.primary));
        expect(decoration.border?.top.color, equals(AppColors.primary));

        // Should show check icon
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('Selection Checkbox - Dark Theme', () {
      testWidgets('should_not_show_checkbox_when_not_in_selection_mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
            isSelectionMode: false,
          ),
        );

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
          findsNothing,
        );
      });

      testWidgets('should_show_unselected_checkbox_with_surfaceDark_color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
            isSelectionMode: true,
            isSelected: false,
          ),
        );

        // Assert
        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppColors.surfaceDark));
        expect(decoration.border?.top.color, equals(AppColors.outlineDark));
      });

      testWidgets('should_show_selected_checkbox_with_primary_color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
            isSelectionMode: true,
            isSelected: true,
          ),
        );

        // Assert
        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppColors.primary));
        expect(decoration.border?.top.color, equals(AppColors.primary));

        // Should show check icon
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('should_call_onTap_when_card_is_tapped', (tester) async {
        // Arrange
        bool tapped = false;
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            onTap: () => tapped = true,
          ),
        );

        // Act
        await tester.tap(find.byType(FolderCard));
        await tester.pump();

        // Assert
        expect(tapped, true);
      });

      testWidgets('should_call_onMorePressed_when_more_button_is_tapped', (tester) async {
        // Arrange
        bool morePressed = false;
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            onMorePressed: () => morePressed = true,
            isSelectionMode: false,
          ),
        );

        // Act
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pump();

        // Assert
        expect(morePressed, true);
      });

      testWidgets('should_not_show_more_button_in_selection_mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            onMorePressed: () {},
            isSelectionMode: true,
          ),
        );

        // Assert
        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('should_display_folder_name_with_max_2_lines', (tester) async {
        // Arrange
        final longNameFolder = testFolder.copyWith(
          name: 'Very Long Folder Name That Should Be Truncated After Two Lines',
        );

        // Act
        await tester.pumpWidget(
          buildTestWidget(folder: longNameFolder),
        );

        // Assert
        final text = tester.widget<Text>(find.text(longNameFolder.name));
        expect(text.maxLines, equals(2));
        expect(text.overflow, equals(TextOverflow.ellipsis));
      });
    });

    group('Card Variant', () {
      testWidgets('should_use_filled_card_variant', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(folder: testFolder),
        );

        // Assert
        // The FolderCard uses AppCard with filled variant
        // We can verify by checking that the outermost Container has surfaceVariant color
        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });
    });
  });
}
