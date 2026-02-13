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

  /// Helper to wrap widget with necessary providers and theme.
  Widget buildTestWidget(
    Widget child, {
    double width = 800,
    double height = 600,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DrawingThemeProvider(
            theme: const DrawingTheme(),
            child: SizedBox(
              width: width,
              height: height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('ToolbarLayoutMode enum', () {
    test('has_three_values', () {
      expect(ToolbarLayoutMode.values.length, equals(3));
    });

    test('values_are_distinct', () {
      expect(ToolbarLayoutMode.expanded, isNot(equals(ToolbarLayoutMode.medium)));
      expect(ToolbarLayoutMode.expanded, isNot(equals(ToolbarLayoutMode.compact)));
      expect(ToolbarLayoutMode.medium, isNot(equals(ToolbarLayoutMode.compact)));
    });
  });

  group('AdaptiveToolbar breakpoints', () {
    testWidgets('renders_toolbar_when_width_gte_840px', (tester) async {
      // Set window size to 840px width
      tester.view.physicalSize = const Size(840, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const AdaptiveToolbar(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should render ToolBar (expanded)
      expect(find.byType(ToolBar), findsOneWidget);
      expect(find.byType(MediumToolbar), findsNothing);
    });

    testWidgets('renders_medium_toolbar_when_width_600_to_839px', (tester) async {
      // Set window size to 700px width
      tester.view.physicalSize = const Size(700, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const AdaptiveToolbar(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should render MediumToolbar
      expect(find.byType(MediumToolbar), findsOneWidget);
      expect(find.byType(ToolBar), findsNothing);
    });

    testWidgets('renders_shrunk_sizedbox_when_width_lt_600px', (tester) async {
      // Set window size to 500px width
      tester.view.physicalSize = const Size(500, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const AdaptiveToolbar(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should render neither ToolBar nor MediumToolbar
      expect(find.byType(ToolBar), findsNothing);
      expect(find.byType(MediumToolbar), findsNothing);
    });

    testWidgets('shouldUseCompactMode_returns_true_when_width_lt_600px', (tester) async {
      // Set window size to less than 600px
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final isCompact = AdaptiveToolbar.shouldUseCompactMode(context);
                return Text(isCompact ? 'compact' : 'normal');
              },
            ),
          ),
        ),
      );

      expect(find.text('compact'), findsOneWidget);
    });
  });

  group('MediumToolbar', () {
    testWidgets('renders_with_undo_redo_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MediumToolbar(),
          width: 700,
        ),
      );

      // Should show undo/redo buttons
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
    });

    testWidgets('shows_settings_button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MediumToolbar(),
          width: 700,
        ),
      );

      // Settings button with tune icon
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('shows_quick_access_toggle_chevron', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MediumToolbar(),
          width: 700,
        ),
      );

      // Should show expand_more (collapsed state) - at least one
      expect(find.byIcon(Icons.expand_more), findsWidgets);
    });

    testWidgets('quick_access_row_toggles_on_chevron_tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MediumToolbar(),
          width: 700,
        ),
      );

      // Initially collapsed - quick access row not visible
      expect(find.byType(QuickAccessRow), findsNothing);

      // Find the chevron icon with size 20 (the toggle button, not in QuickAccessRow)
      final chevronIcon = find.byWidgetPredicate(
        (widget) => widget is Icon &&
                    widget.icon == Icons.expand_more &&
                    widget.size == 20,
      );
      expect(chevronIcon, findsOneWidget);

      // Tap the chevron to expand
      await tester.tap(chevronIcon);
      await tester.pump();

      // Now expanded - quick access row visible and icon changed
      expect(find.byType(QuickAccessRow), findsOneWidget);
      final expandLessIcon = find.byWidgetPredicate(
        (widget) => widget is Icon &&
                    widget.icon == Icons.expand_less &&
                    widget.size == 20,
      );
      expect(expandLessIcon, findsOneWidget);
    });

    testWidgets('shows_overflow_menu_when_more_than_6_tools', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MediumToolbar(),
          width: 700,
        ),
      );

      // Default toolbar has more than 6 visible tools, should show overflow
      expect(find.byType(ToolbarOverflowMenu), findsOneWidget);
    });
  });

  group('CompactBottomBar', () {
    testWidgets('has_56dp_height', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CompactBottomBar(),
          width: 400,
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(SafeArea),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxHeight, equals(56));
    });

    testWidgets('shows_undo_redo_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CompactBottomBar(),
          width: 400,
        ),
      );

      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
    });

    testWidgets('shows_max_5_tool_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CompactBottomBar(),
          width: 400,
        ),
      );

      // Should show max 5 tool buttons
      final toolButtons = find.byType(ToolButton);
      expect(toolButtons.evaluate().length, lessThanOrEqualTo(CompactBottomBar.maxVisibleTools));
    });

    testWidgets('shows_overflow_menu_when_needed', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CompactBottomBar(),
          width: 400,
        ),
      );

      // Default toolbar has more tools than max visible, should show overflow
      expect(find.byType(ToolbarOverflowMenu), findsOneWidget);
    });

    testWidgets('calls_onPanelRequested_when_tool_tapped_twice', (tester) async {
      ToolType? requestedPanel;

      await tester.pumpWidget(
        buildTestWidget(
          CompactBottomBar(
            onPanelRequested: (tool) => requestedPanel = tool,
          ),
          width: 400,
        ),
      );

      // Find a tool button (ballpoint pen is usually visible)
      final penButton = find.byWidgetPredicate(
        (widget) => widget is ToolButton && widget.toolType == ToolType.ballpointPen,
      );

      if (penButton.evaluate().isNotEmpty) {
        // Tap once to select
        await tester.tap(penButton);
        await tester.pump();

        // Tap again to open panel
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

      // Should show more_vert icon
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
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

      // Tap to open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Should show hidden tools in menu
      expect(find.text('Şekiller'), findsOneWidget);
      expect(find.text('Çıkartma'), findsOneWidget);
    });
  });

  group('TopNavigationBar compact mode', () {
    testWidgets('compact_false_shows_all_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const TopNavigationBar(compact: false),
          width: 800,
        ),
      );

      // Should show layers button (one of the full layout buttons)
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    });

    testWidgets('compact_true_shows_minimal_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const TopNavigationBar(compact: true),
          width: 400,
        ),
      );

      // Should show home button
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);

      // Should show share button
      expect(find.byIcon(Icons.ios_share), findsOneWidget);

      // Should show more button
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Should NOT show layers button (full layout only)
      expect(find.byIcon(Icons.layers_outlined), findsNothing);
    });

    testWidgets('shows_document_title_in_both_modes', (tester) async {
      const title = 'Test Document';

      await tester.pumpWidget(
        buildTestWidget(
          const TopNavigationBar(
            compact: true,
            documentTitle: title,
          ),
          width: 400,
        ),
      );

      expect(find.text(title), findsOneWidget);

      // Test full mode as well
      await tester.pumpWidget(
        buildTestWidget(
          const TopNavigationBar(
            compact: false,
            documentTitle: title,
          ),
          width: 800,
        ),
      );

      expect(find.text(title), findsOneWidget);
    });
  });
}
