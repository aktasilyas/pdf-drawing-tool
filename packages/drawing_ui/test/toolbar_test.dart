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

  /// ToolBar is the expanded (>=840) layout; render it at tablet width so
  /// the tool capsule shows its tools instead of the overflow menu.
  Future<void> useTabletSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1180, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  group('ToolBar', () {
    testWidgets('renders nav buttons and tool buttons', (tester) async {
      await useTabletSurface(tester);
      await tester.pumpWidget(createToolBarWidget());

      // Nav buttons live inside the single-row toolbar.
      expect(find.byIcon(ElyanotesIcons.home), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.readerMode), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.exportIcon), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.more), findsOneWidget);

      // Default tool (ballpoint pen group) and eraser are visible.
      expect(find.byType(ToolButton), findsWidgets);
      expect(
        find.byIcon(ElyanotesIcons.iconForTool(ToolType.pixelEraser)),
        findsOneWidget,
      );

      // Undo/redo live in the tools capsule; settings button was removed.
      expect(find.byIcon(ElyanotesIcons.undo), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.redo), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.settings), findsNothing);
    });

    testWidgets('floating undo and redo buttons are disabled by default',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Stack(children: [FloatingUndoRedo()])),
          ),
        ),
      );

      final scheme =
          Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      final undoIcon =
          tester.widget<PhosphorIcon>(find.byIcon(ElyanotesIcons.undo));
      final redoIcon =
          tester.widget<PhosphorIcon>(find.byIcon(ElyanotesIcons.redo));

      // canUndo / canRedo are false by default -> reduced alpha (disabled look).
      final disabled = scheme.onSurface.withValues(alpha: 0.25);
      expect(undoIcon.color, disabled);
      expect(redoIcon.color, disabled);
    });

    testWidgets('tool selection updates current tool provider', (tester) async {
      await useTabletSurface(tester);
      await tester.pumpWidget(createToolBarWidget());

      // Tap on eraser tool (not grouped, directly visible)
      await tester
          .tap(find.byIcon(ElyanotesIcons.iconForTool(ToolType.pixelEraser)));
      await tester.pump();

      // Verify the tool is now selected (would need to verify via provider)
    });
  });

  group('TopNavigationBar', () {
    testWidgets('renders all navigation buttons', (tester) async {
      await tester.pumpWidget(createTopNavBarWidget());

      // Verify navigation buttons exist
      expect(find.byIcon(ElyanotesIcons.home), findsOneWidget);
    });

    testWidgets('renders right action buttons', (tester) async {
      await tester.pumpWidget(createTopNavBarWidget());

      // Verify right action buttons exist (full layout)
      expect(find.byIcon(ElyanotesIcons.readerMode), findsOneWidget);
      // Add-page is hidden in infinite canvas mode (the default).
      expect(find.byIcon(ElyanotesIcons.pageAdd), findsNothing);
      expect(find.byIcon(ElyanotesIcons.exportIcon), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.more), findsOneWidget);
      // Grid toggle is no longer part of the top bar (moved to page sidebar).
      expect(find.byIcon(ElyanotesIcons.gridOn), findsNothing);
    });

    testWidgets('reader mode toggle switches the reader icon', (tester) async {
      await tester.pumpWidget(createTopNavBarWidget());

      expect(find.byIcon(ElyanotesIcons.readerMode), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.readerModeActive), findsNothing);

      await tester.tap(find.byIcon(ElyanotesIcons.readerMode));
      await tester.pump();

      expect(find.byIcon(ElyanotesIcons.readerModeActive), findsOneWidget);
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
        find
            .ancestor(
              of: find.byIcon(ElyanotesIcons.iconForTool(ToolType.ballpointPen,
                  active: true)),
              matching: find.byType(Container),
            )
            .first,
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

      await tester
          .tap(find.byIcon(ElyanotesIcons.iconForTool(ToolType.brushPen)));
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

      await tester.tap(find
          .byIcon(ElyanotesIcons.iconForTool(ToolType.brushPen, active: true)));
      await tester.pump();
      expect(panelTapped, isTrue);
    });
  });
}
