import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_card.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_tile_art.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';
import '../../../../helpers/l10n.dart';

Color? _artColor(WidgetTester tester) {
  final paints = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .where((p) => p.painter is FolderTileArt);
  expect(paints, hasLength(1));
  return (paints.single.painter! as FolderTileArt).color;
}

BoxDecoration _checkboxDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(LibrarySelectionCheckbox),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

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
        child: localizedApp(
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
      testWidgets('should_use_textPrimaryLight_for_folder_name',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('Test Folder'));
        expect(text.style?.color, equals(AppPalette.light.textPrimary));
      });

      testWidgets('should_use_textSecondaryLight_for_document_count',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('5 belge'));
        expect(text.style?.color, equals(AppPalette.light.textMuted));
      });

      testWidgets('should_draw_folder_art_with_folder_color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
          ),
        );

        // Assert
        expect(_artColor(tester), equals(Color(testFolder.colorValue)));
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
        expect(text.style?.color, equals(AppPalette.dark.textPrimary));
      });

      testWidgets('should_use_textSecondaryDark_for_document_count',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('5 belge'));
        expect(text.style?.color, equals(AppPalette.dark.textMuted));
      });

      testWidgets('should_draw_folder_art_with_folder_color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
          ),
        );

        // Assert
        expect(_artColor(tester), equals(Color(testFolder.colorValue)));
      });
    });

    group('Selection Checkbox - Light Theme', () {
      testWidgets('should_not_show_checkbox_when_not_in_selection_mode',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
            isSelectionMode: false,
          ),
        );

        expect(find.byType(LibrarySelectionCheckbox), findsNothing);
      });

      testWidgets('should_show_unselected_checkbox_with_elevated_fill',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
            isSelectionMode: true,
            isSelected: false,
          ),
        );

        final decoration = _checkboxDecoration(tester);
        expect(
          decoration.color,
          equals(AppPalette.light.surfaceElevated.withValues(alpha: 0.92)),
        );
        expect(
          decoration.border?.top.color,
          equals(AppPalette.light.textMuted),
        );
        expect(find.byIcon(ElyanotesIcons.libraryCheck), findsNothing);
      });

      testWidgets('should_show_selected_checkbox_with_accent_color',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: false,
            isSelectionMode: true,
            isSelected: true,
          ),
        );

        final decoration = _checkboxDecoration(tester);
        expect(decoration.color, equals(AppPalette.light.accent));
        expect(find.byIcon(ElyanotesIcons.libraryCheck), findsOneWidget);
      });
    });

    group('Selection Checkbox - Dark Theme', () {
      testWidgets('should_not_show_checkbox_when_not_in_selection_mode',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
            isSelectionMode: false,
          ),
        );

        expect(find.byType(LibrarySelectionCheckbox), findsNothing);
      });

      testWidgets('should_show_unselected_checkbox_with_elevated_fill',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
            isSelectionMode: true,
            isSelected: false,
          ),
        );

        final decoration = _checkboxDecoration(tester);
        expect(
          decoration.color,
          equals(AppPalette.dark.surfaceElevated.withValues(alpha: 0.92)),
        );
        expect(
          decoration.border?.top.color,
          equals(AppPalette.dark.textMuted),
        );
        expect(find.byIcon(ElyanotesIcons.libraryCheck), findsNothing);
      });

      testWidgets('should_show_selected_checkbox_with_accent_color',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            isDark: true,
            isSelectionMode: true,
            isSelected: true,
          ),
        );

        final decoration = _checkboxDecoration(tester);
        expect(decoration.color, equals(AppPalette.dark.accent));
        expect(find.byIcon(ElyanotesIcons.libraryCheck), findsOneWidget);
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

      testWidgets('should_call_onMorePressed_when_more_button_is_tapped',
          (tester) async {
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
        await tester.tap(find.byKey(const Key('folder_card_more_button')));
        await tester.pump();

        // Assert
        expect(morePressed, true);
      });

      testWidgets('should_not_show_more_button_in_selection_mode',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            folder: testFolder,
            onMorePressed: () {},
            isSelectionMode: true,
          ),
        );

        // Assert
        expect(find.byKey(const Key('folder_card_more_button')), findsNothing);
      });

      testWidgets('should_display_folder_name_with_max_1_line', (tester) async {
        // Arrange
        final longNameFolder = testFolder.copyWith(
          name:
              'Very Long Folder Name That Should Be Truncated After Two Lines',
        );

        // Act
        await tester.pumpWidget(
          buildTestWidget(folder: longNameFolder),
        );

        // Assert
        final text = tester.widget<Text>(find.text(longNameFolder.name));
        expect(text.maxLines, equals(1));
        expect(text.overflow, equals(TextOverflow.ellipsis));
      });
    });
  });
}
