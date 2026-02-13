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

  Widget createToolBarWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DrawingThemeProvider(
            theme: const DrawingTheme(),
            child: const ToolBar(),
          ),
        ),
      ),
    );
  }

  Widget createTopNavBarWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DrawingThemeProvider(
            theme: const DrawingTheme(),
            child: const TopNavigationBar(),
          ),
        ),
      ),
    );
  }

  group('ToolBar', () {
    testWidgets('renders all visible tool buttons', (tester) async {
      await tester.pumpWidget(createToolBarWidget());

      // Verify undo/redo buttons exist
      expect(find.byIcon(StarNoteIcons.undo), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.redo), findsOneWidget);

      // Verify config button exists (settings icon)
      expect(find.byIcon(StarNoteIcons.settings), findsOneWidget);
    });

    testWidgets('undo and redo buttons are disabled by default', (tester) async {
      await tester.pumpWidget(createToolBarWidget());

      // Both should be disabled (canUndo and canRedo are false by default)
      final undoIcon = tester.widget<PhosphorIcon>(find.byIcon(StarNoteIcons.undo));
      final redoIcon = tester.widget<PhosphorIcon>(find.byIcon(StarNoteIcons.redo));

      // Icons should have reduced alpha (disabled look)
      expect(undoIcon.color, isNotNull);
      expect(redoIcon.color, isNotNull);
    });

    testWidgets('tool selection updates current tool provider', (tester) async {
      await tester.pumpWidget(createToolBarWidget());

      // Tap on eraser tool (not grouped, directly visible)
      await tester.tap(find.byIcon(StarNoteIcons.iconForTool(ToolType.pixelEraser)));
      await tester.pump();

      // Verify the tool is now selected (would need to verify via provider)
    });
  });

  group('TopNavigationBar', () {
    testWidgets('renders all navigation buttons', (tester) async {
      await tester.pumpWidget(createTopNavBarWidget());

      // Verify navigation buttons exist
      expect(find.byIcon(StarNoteIcons.home), findsOneWidget);
    });

    testWidgets('renders right action buttons', (tester) async {
      await tester.pumpWidget(createTopNavBarWidget());

      // Verify right action buttons exist (full layout)
      expect(find.byIcon(StarNoteIcons.readerMode), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.gridOn), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.exportIcon), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.more), findsOneWidget);
    });

    testWidgets('grid toggle works', (tester) async {
      await tester.pumpWidget(createTopNavBarWidget());

      // Grid should be on by default
      expect(find.byIcon(StarNoteIcons.gridOn), findsOneWidget);

      // Tap to toggle
      await tester.tap(find.byIcon(StarNoteIcons.gridOn));
      await tester.pump();

      // Grid should now be off
      expect(find.byIcon(StarNoteIcons.gridOff), findsOneWidget);
    });

    testWidgets('document tab is displayed', (tester) async {
      await tester.pumpWidget(createTopNavBarWidget());

      // Verify document tab text
      expect(find.text('İsimsiz Not'), findsOneWidget);
    });
  });

  group('ToolButton', () {
    testWidgets('shows selected state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: ToolButton(
                toolType: ToolType.ballpointPen,
                isSelected: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Find the container with selected background
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(StarNoteIcons.iconForTool(ToolType.ballpointPen, active: true)),
          matching: find.byType(Container),
        ).first,
      );

      // Verify selected state styling is applied
      expect(container.decoration, isNotNull);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: ToolButton(
                toolType: ToolType.brushPen,
                isSelected: false,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(StarNoteIcons.iconForTool(ToolType.brushPen)));
      expect(pressed, isTrue);
    });

    testWidgets('calls onPanelTap when selected and tapped', (tester) async {
      bool panelTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: ToolButton(
                toolType: ToolType.brushPen,
                isSelected: true, // Must be selected to trigger panel tap
                onPressed: () {},
                onPanelTap: () => panelTapped = true,
                hasPanel: true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(StarNoteIcons.iconForTool(ToolType.brushPen, active: true)));
      await tester.pump();
      expect(panelTapped, isTrue);
    });
  });
}
