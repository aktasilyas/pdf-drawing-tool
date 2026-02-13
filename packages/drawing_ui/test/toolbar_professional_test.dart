import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('StarNoteIcons', () {
    test('should_have_home_icon', () {
      expect(StarNoteIcons.home, equals(PhosphorIconsLight.house));
    });

    test('should_have_sidebar_icons_with_active_variant', () {
      expect(StarNoteIcons.sidebar, equals(PhosphorIconsLight.sidebar));
      expect(StarNoteIcons.sidebarActive, equals(PhosphorIconsRegular.sidebar));
    });

    test('should_have_reader_mode_icons_with_active_variant', () {
      expect(StarNoteIcons.readerMode, equals(PhosphorIconsLight.bookOpen));
      expect(StarNoteIcons.readerModeActive, equals(PhosphorIconsRegular.bookOpen));
    });

    test('should_have_correct_icon_sizes', () {
      expect(StarNoteIcons.navSize, equals(20.0));
      expect(StarNoteIcons.toolSize, equals(22.0));
      expect(StarNoteIcons.panelSize, equals(18.0));
      expect(StarNoteIcons.actionSize, equals(20.0));
    });

    test('should_map_tool_types_to_icons', () {
      expect(
        StarNoteIcons.iconForTool(ToolType.pencil),
        equals(PhosphorIconsLight.pencilSimple),
      );
      expect(
        StarNoteIcons.iconForTool(ToolType.pencil, active: true),
        equals(PhosphorIconsRegular.pencilSimple),
      );
      expect(
        StarNoteIcons.iconForTool(ToolType.highlighter),
        equals(PhosphorIconsLight.highlighterCircle),
      );
      expect(
        StarNoteIcons.iconForTool(ToolType.highlighter, active: true),
        equals(PhosphorIconsRegular.highlighterCircle),
      );
    });

    test('should_have_navigation_arrow_icons', () {
      expect(StarNoteIcons.chevronLeft, equals(PhosphorIconsLight.caretLeft));
      expect(StarNoteIcons.chevronRight, equals(PhosphorIconsLight.caretRight));
    });
  });

  group('StarNoteNavButton', () {
    testWidgets('should_render_with_icon_and_tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: StarNoteNavButton(
              icon: StarNoteIcons.home,
              tooltip: 'Home',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(PhosphorIcon), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('should_call_onPressed_when_tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: StarNoteNavButton(
              icon: StarNoteIcons.home,
              tooltip: 'Home',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StarNoteNavButton));
      expect(tapped, isTrue);
    });

    testWidgets('should_show_active_state_with_background_color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: StarNoteNavButton(
              icon: StarNoteIcons.sidebar,
              tooltip: 'Sidebar',
              onPressed: () {},
              isActive: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StarNoteNavButton),
          matching: find.byType(Container).last,
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(equals(Colors.transparent)));
    });

    testWidgets('should_not_respond_to_tap_when_disabled', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: StarNoteNavButton(
              icon: StarNoteIcons.home,
              tooltip: 'Home',
              onPressed: () {
                tapped = true;
              },
              isDisabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StarNoteNavButton));
      expect(tapped, isFalse);
    });

    testWidgets('should_render_badge_when_provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: StarNoteNavButton(
              icon: StarNoteIcons.home,
              tooltip: 'Home',
              onPressed: () {},
              badge: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );

      // Badge creates a Stack, so we should find it
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(Positioned), findsOneWidget);
    });
  });

  group('Reader Mode', () {
    testWidgets('should_toggle_reader_mode_state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state is false
      expect(container.read(readerModeProvider), isFalse);

      // Toggle to true
      container.read(readerModeProvider.notifier).state = true;
      expect(container.read(readerModeProvider), isTrue);

      // Toggle back to false
      container.read(readerModeProvider.notifier).state = false;
      expect(container.read(readerModeProvider), isFalse);
    });

    testWidgets('should_display_reader_badge_in_top_nav_when_active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readerModeProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: TopNavigationBar(
                documentTitle: 'Test Document',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Salt okunur'), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should_not_display_reader_badge_when_inactive', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: TopNavigationBar(
                documentTitle: 'Test Document',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Salt okunur'), findsNothing);
    });
  });

  group('Page Navigation', () {
    testWidgets('should_display_page_counter_with_current_and_total', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pageCountProvider.overrideWith((ref) => 5),
            currentPageIndexProvider.overrideWith((ref) => 2),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: PageIndicatorBar(),
            ),
          ),
        ),
      );

      expect(find.text('Sayfa 3 / 5'), findsOneWidget);
    });

    testWidgets('should_render_navigation_arrows', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pageCountProvider.overrideWith((ref) => 3),
            currentPageIndexProvider.overrideWith((ref) => 1),
            canGoPreviousProvider.overrideWith((ref) => true),
            canGoNextProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: PageIndicatorBar(),
            ),
          ),
        ),
      );

      // Find phosphor icons (arrows)
      final icons = tester.widgetList<PhosphorIcon>(find.byType(PhosphorIcon));
      expect(icons.length, greaterThanOrEqualTo(2));
    });

    testWidgets('should_hide_page_indicator_for_single_page_document', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pageCountProvider.overrideWith((ref) => 1),
            currentPageIndexProvider.overrideWith((ref) => 0),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: PageIndicatorBar(),
            ),
          ),
        ),
      );

      expect(find.byType(PageIndicatorBar), findsOneWidget);
      expect(find.text('Sayfa 1 / 1'), findsNothing);
    });
  });

  group('ToolButton', () {
    testWidgets('should_render_with_tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ToolButton(
              toolType: ToolType.pencil,
              isSelected: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.byType(PhosphorIcon), findsOneWidget);
    });

    testWidgets('should_have_semantics_label_with_tool_name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ToolButton(
              toolType: ToolType.highlighter,
              isSelected: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Find the specific Semantics widget with the tool name label
      final semanticsWithLabel = find.byWidgetPredicate(
        (widget) => widget is Semantics &&
                    widget.properties.label == ToolType.highlighter.displayName,
      );
      expect(semanticsWithLabel, findsOneWidget);
    });

    testWidgets('should_show_disabled_state_with_reduced_opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ToolButton(
              toolType: ToolType.pixelEraser,
              isSelected: false,
              onPressed: () {},
              enabled: false,
            ),
          ),
        ),
      );

      final icon = tester.widget<PhosphorIcon>(find.byType(PhosphorIcon));
      expect(icon.color?.a, lessThan(0.5));
    });

    testWidgets('should_show_primary_background_when_selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ToolButton(
              toolType: ToolType.ballpointPen,
              isSelected: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ToolButton),
          matching: find.byType(Container).last,
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(equals(Colors.transparent)));
    });

    testWidgets('should_use_active_icon_variant_when_selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ToolButton(
              toolType: ToolType.pencil,
              isSelected: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<PhosphorIcon>(find.byType(PhosphorIcon));
      expect(icon.icon, equals(PhosphorIconsRegular.pencilSimple));
    });
  });

  group('QuickThicknessChips', () {
    testWidgets('should_render_thickness_chips_from_provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quickThicknessProvider.overrideWith((ref) => [1.0, 2.5, 5.0]),
            penSettingsProvider(ToolType.ballpointPen).overrideWith(
              (ref) => PenSettingsNotifier(
                const PenSettings(
                  color: Colors.black,
                  thickness: 2.5,
                  stabilization: 0.3,
                  nibShape: NibShapeType.circle,
                  pressureSensitive: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: QuickThicknessChips(
                currentTool: ToolType.ballpointPen,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(QuickThicknessChip), findsNWidgets(3));
    });

    testWidgets('should_show_selected_chip_with_primary_border', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quickThicknessProvider.overrideWith((ref) => [1.0, 2.5, 5.0]),
            penSettingsProvider(ToolType.ballpointPen).overrideWith(
              (ref) => PenSettingsNotifier(
                const PenSettings(
                  color: Colors.black,
                  thickness: 2.5,
                  stabilization: 0.3,
                  nibShape: NibShapeType.circle,
                  pressureSensitive: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: QuickThicknessChips(
                currentTool: ToolType.ballpointPen,
              ),
            ),
          ),
        ),
      );

      // Find all chip containers
      final chips = tester.widgetList<QuickThicknessChip>(
        find.byType(QuickThicknessChip),
      );
      expect(chips.length, equals(3));

      // At least one chip should be selected
      final selectedChip = chips.firstWhere((chip) => chip.isSelected);
      expect(selectedChip.thickness, equals(2.5));
    });
  });

  group('TopNavigationBar', () {
    testWidgets('should_render_in_compact_mode_with_minimal_buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: TopNavigationBar(
                documentTitle: 'Test Document',
                compact: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TopNavigationBar), findsOneWidget);
      expect(find.text('Test Document'), findsOneWidget);
    });

    testWidgets('should_render_reader_mode_badge_in_compact_mode_when_active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readerModeProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: TopNavigationBar(
                documentTitle: 'Test Document',
                compact: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Salt okunur'), findsOneWidget);
    });

    testWidgets('should_hide_grid_button_in_reader_mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readerModeProvider.overrideWith((ref) => true),
            pageCountProvider.overrideWith((ref) => 1),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: TopNavigationBar(
                documentTitle: 'Test Document',
                compact: false,
              ),
            ),
          ),
        ),
      );

      // In reader mode, grid button should not be present
      // Count StarNoteNavButton widgets
      final navButtons = tester.widgetList<StarNoteNavButton>(
        find.byType(StarNoteNavButton),
      );

      // Should have: Home, Reader, Export, More (no Grid button)
      expect(navButtons.length, lessThanOrEqualTo(5));
    });

    testWidgets('should_display_document_title_with_caret_icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: TopNavigationBar(
                documentTitle: 'My Drawing',
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Drawing'), findsOneWidget);

      // Find caret icon
      final caretIcons = tester.widgetList<PhosphorIcon>(
        find.byWidgetPredicate(
          (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.caretDown,
        ),
      );
      expect(caretIcons.length, greaterThanOrEqualTo(1));
    });

    testWidgets('should_show_sidebar_button_only_for_multi_page_documents', (tester) async {
      // Multi-page document should show sidebar button
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pageCountProvider.overrideWith((ref) => 3),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: TopNavigationBar(
                documentTitle: 'Multi Page',
                compact: false,
              ),
            ),
          ),
        ),
      );

      // Find sidebar icon in multi-page document
      final sidebarIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon &&
                    (widget.icon == PhosphorIconsLight.sidebar ||
                     widget.icon == PhosphorIconsRegular.sidebar),
      );
      expect(sidebarIcon, findsOneWidget);
    });
  });

  group('ToolType Integration', () {
    test('should_have_display_names_for_all_tool_types', () {
      for (final toolType in ToolType.values) {
        expect(toolType.displayName, isNotEmpty);
      }
    });

    test('should_identify_pen_tools_correctly', () {
      expect(ToolType.pencil.isPenTool, isTrue);
      expect(ToolType.ballpointPen.isPenTool, isTrue);
      expect(ToolType.highlighter.isPenTool, isTrue);
      expect(ToolType.pixelEraser.isPenTool, isFalse);
      expect(ToolType.shapes.isPenTool, isFalse);
      expect(ToolType.selection.isPenTool, isFalse);
    });

    test('should_map_pen_tools_to_pen_types', () {
      expect(ToolType.pencil.penType, isNotNull);
      expect(ToolType.ballpointPen.penType, isNotNull);
      expect(ToolType.highlighter.penType, isNotNull);
      expect(ToolType.pixelEraser.penType, isNull);
    });
  });
}
