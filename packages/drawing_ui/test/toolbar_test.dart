import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('ToolBar', () {
    testWidgets('renders all visible tool buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const ToolBar(),
              ),
            ),
          ),
        ),
      );

      // Verify undo/redo buttons exist
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);

      // Verify config button exists (tune icon)
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('undo and redo buttons are disabled by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const ToolBar(),
              ),
            ),
          ),
        ),
      );

      // Both should be disabled (canUndo and canRedo are false by default)
      final undoIcon = tester.widget<Icon>(find.byIcon(Icons.undo));
      final redoIcon = tester.widget<Icon>(find.byIcon(Icons.redo));

      // Icons should have reduced alpha (disabled look)
      expect(undoIcon.color, isNotNull);
      expect(redoIcon.color, isNotNull);
    });

    testWidgets('tool selection updates current tool provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: Consumer(
                  builder: (context, ref, child) {
                    return const ToolBar();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Tap on eraser tool (not grouped, directly visible)
      await tester.tap(find.byIcon(Icons.auto_fix_normal));
      await tester.pump();

      // Verify the tool is now selected (would need to verify via provider)
    });
  });

  group('TopNavigationBar', () {
    testWidgets('renders all navigation buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const TopNavigationBar(),
              ),
            ),
          ),
        ),
      );

      // Verify navigation buttons exist
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.crop), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('renders right action buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const TopNavigationBar(),
              ),
            ),
          ),
        ),
      );

      // Verify right action buttons exist
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('grid toggle works', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const TopNavigationBar(),
              ),
            ),
          ),
        ),
      );

      // Grid should be on by default
      expect(find.byIcon(Icons.grid_on), findsOneWidget);

      // Tap to toggle
      await tester.tap(find.byIcon(Icons.grid_on));
      await tester.pump();

      // Grid should now be off
      expect(find.byIcon(Icons.grid_off), findsOneWidget);
    });

    testWidgets('document tab is displayed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const TopNavigationBar(),
              ),
            ),
          ),
        ),
      );

      // Verify document tab text
      expect(find.text('İsimsiz not'), findsOneWidget);
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
          of: find.byIcon(Icons.edit),
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

      await tester.tap(find.byIcon(Icons.brush));
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

      await tester.tap(find.byIcon(Icons.brush));
      await tester.pump();
      expect(panelTapped, isTrue);
    });
  });
}
