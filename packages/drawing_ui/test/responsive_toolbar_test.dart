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

  group('ToolbarLayoutMode enum', () {
    test('has_three_values', () {
      expect(ToolbarLayoutMode.values.length, equals(3));
    });

    test('values_are_distinct', () {
      expect(ToolbarLayoutMode.expanded, isNot(equals(ToolbarLayoutMode.medium)));
      expect(ToolbarLayoutMode.expanded, isNot(equals(ToolbarLayoutMode.compact)));
      expect(ToolbarLayoutMode.medium, isNot(equals(ToolbarLayoutMode.compact)));
    });

    test('compactBreakpoint_is_600', () {
      expect(ToolbarLayoutMode.compactBreakpoint, equals(600));
    });

    test('expandedBreakpoint_is_840', () {
      expect(ToolbarLayoutMode.expandedBreakpoint, equals(840));
    });
  });

  group('AdaptiveToolbar breakpoints', () {
    testWidgets('renders_toolbar_when_width_gte_840px', (tester) async {
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

      expect(find.byType(ToolBar), findsOneWidget);
      expect(find.byType(MediumToolbar), findsNothing);
    });

    testWidgets('renders_medium_toolbar_when_width_600_to_839px', (tester) async {
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

      expect(find.byType(MediumToolbar), findsOneWidget);
      expect(find.byType(ToolBar), findsNothing);
    });

    testWidgets('renders_shrunk_sizedbox_when_width_lt_600px', (tester) async {
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

      expect(find.byType(ToolBar), findsNothing);
      expect(find.byType(MediumToolbar), findsNothing);
    });

    testWidgets('shouldUseCompactMode_returns_true_when_width_lt_600px', (tester) async {
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

  group('TopNavigationBar compact mode', () {
    Widget buildTestWidget(Widget child, {double width = 800, double height = 600}) {
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

    testWidgets('compact_false_shows_all_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const TopNavigationBar(compact: false), width: 800),
      );

      expect(find.byIcon(StarNoteIcons.readerMode), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.gridOn), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.exportIcon), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.more), findsOneWidget);
    });

    testWidgets('compact_true_shows_minimal_buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const TopNavigationBar(compact: true), width: 400),
      );

      expect(find.byIcon(StarNoteIcons.home), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.exportIcon), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.more), findsOneWidget);
      // Full-mode buttons should not appear in compact mode
      expect(find.byIcon(StarNoteIcons.readerMode), findsNothing);
      expect(find.byIcon(StarNoteIcons.gridOn), findsNothing);
    });

    testWidgets('shows_document_title_in_both_modes', (tester) async {
      const title = 'Test Document';

      await tester.pumpWidget(
        buildTestWidget(
          const TopNavigationBar(compact: true, documentTitle: title),
          width: 400,
        ),
      );
      expect(find.text(title), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(
          const TopNavigationBar(compact: false, documentTitle: title),
          width: 800,
        ),
      );
      expect(find.text(title), findsOneWidget);
    });
  });
}
