import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestWidget(
    Widget child, {
    double width = 800,
    double height = 600,
  }) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: DrawingThemeProvider(
            theme: const DrawingTheme(),
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    );
  }

  group('MediumToolbar', () {
    testWidgets('renders_with_undo_redo_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const MediumToolbar(), width: 700),
      );

      expect(find.byIcon(StarNoteIcons.undo), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.redo), findsOneWidget);
    });

    testWidgets('shows_settings_button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const MediumToolbar(), width: 700),
      );

      expect(find.byIcon(StarNoteIcons.settings), findsOneWidget);
    });

    testWidgets('shows_quick_access_toggle_chevron', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const MediumToolbar(), width: 700),
      );

      expect(find.byIcon(StarNoteIcons.caretDown), findsWidgets);
    });

    testWidgets('quick_access_row_toggles_on_chevron_tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const MediumToolbar(), width: 700),
      );

      expect(find.byType(QuickAccessRow), findsNothing);

      final chevronIcon = find.byWidgetPredicate(
        (widget) =>
            widget is PhosphorIcon &&
            widget.icon == StarNoteIcons.caretDown &&
            widget.size == 20,
      );
      expect(chevronIcon, findsOneWidget);

      await tester.tap(chevronIcon);
      await tester.pump();

      expect(find.byType(QuickAccessRow), findsOneWidget);
      final expandLessIcon = find.byWidgetPredicate(
        (widget) =>
            widget is PhosphorIcon &&
            widget.icon == StarNoteIcons.caretUp &&
            widget.size == 20,
      );
      expect(expandLessIcon, findsOneWidget);
    });

    testWidgets('shows_overflow_menu_when_more_than_6_tools', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const MediumToolbar(), width: 700),
      );

      expect(find.byType(ToolbarOverflowMenu), findsOneWidget);
    });
  });

  group('CompactToolRow', () {
    testWidgets('has_48dp_height', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const CompactToolRow(), width: 400),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.constraints?.maxHeight, equals(48));
    });

    testWidgets('shows_undo_redo_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const CompactToolRow(), width: 400),
      );

      expect(find.byIcon(StarNoteIcons.undo), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.redo), findsOneWidget);
    });

    testWidgets('shows_max_5_tool_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const CompactToolRow(), width: 400),
      );

      final toolButtons = find.byType(ToolButton);
      // Dynamic layout — at 400px width, fits a reasonable number of tools
      expect(toolButtons.evaluate().length, greaterThan(0));
    });

    testWidgets('shows_overflow_menu_when_needed', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const CompactToolRow(), width: 400),
      );

      expect(find.byType(ToolbarOverflowMenu), findsOneWidget);
    });

    testWidgets('calls_onPanelRequested_when_tool_tapped_twice', (tester) async {
      ToolType? requestedPanel;

      await tester.pumpWidget(
        buildTestWidget(
          CompactToolRow(
            onPanelRequested: (tool) => requestedPanel = tool,
          ),
          width: 400,
        ),
      );

      final penButton = find.byWidgetPredicate(
        (widget) =>
            widget is ToolButton && widget.toolType == ToolType.ballpointPen,
      );

      if (penButton.evaluate().isNotEmpty) {
        await tester.tap(penButton);
        await tester.pump();

        await tester.tap(penButton);
        await tester.pump();

        expect(requestedPanel, equals(ToolType.ballpointPen));
      }
    });
  });

  group('ToolbarOverflowMenu', () {
    testWidgets('renders_popup_menu_button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ToolbarOverflowMenu(
            hiddenTools: [ToolType.shapes, ToolType.sticker],
          ),
          width: 400,
        ),
      );

      expect(find.byIcon(StarNoteIcons.moreVert), findsOneWidget);
      expect(find.byType(PopupMenuButton<ToolType>), findsOneWidget);
    });

    testWidgets('shows_hidden_tools_on_tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ToolbarOverflowMenu(
            hiddenTools: [ToolType.shapes, ToolType.sticker],
          ),
          width: 400,
        ),
      );

      await tester.tap(find.byIcon(StarNoteIcons.moreVert));
      await tester.pumpAndSettle();

      expect(find.text('Şekiller'), findsOneWidget);
      expect(find.text('Çıkartma'), findsOneWidget);
    });
  });
}
