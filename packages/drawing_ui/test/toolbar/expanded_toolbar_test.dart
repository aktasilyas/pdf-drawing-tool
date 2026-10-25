import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../golden/helpers/chrome_theme.dart';

bool _isIgnoring(Widget w) => w is IgnorePointer && w.ignoring;

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> pumpToolBar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: chromeTheme(Brightness.light),
          home: const Scaffold(
            body: DrawingThemeProvider(
              theme: DrawingTheme(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ToolBar(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return ProviderScope.containerOf(tester.element(find.byType(ToolBar)));
  }

  Finder undoButton() => find.byWidgetPredicate(
        (w) => w is ChromeIconButton && w.icon == ElyanotesIcons.undo,
      );

  Finder redoButton() => find.byWidgetPredicate(
        (w) => w is ChromeIconButton && w.icon == ElyanotesIcons.redo,
      );

  group('ToolBar at 1180', () {
    testWidgets('renders nav, tools and actions capsules', (tester) async {
      await pumpToolBar(tester);

      expect(find.byType(ChromeCapsule), findsNWidgets(3));
      final nav = find.byType(ChromeCapsule).at(0);
      final tools = find.byType(ChromeCapsule).at(1);
      final actions = find.byType(ChromeCapsule).at(2);
      expect(
        find.descendant(of: nav, matching: find.byIcon(ElyanotesIcons.home)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tools, matching: find.byType(ToolButton)),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: actions,
          matching: find.byIcon(ElyanotesIcons.exportIcon),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: actions,
          matching: find.byIcon(ElyanotesIcons.more),
        ),
        findsOneWidget,
      );
    });

    testWidgets('band is 64dp and uses the background', (tester) async {
      await pumpToolBar(tester);

      expect(tester.getSize(find.byType(ToolBar)).height, 64);
      final palette = ChromePalette.of(tester.element(find.byType(ToolBar)));
      final band = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ToolBar),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(band.color, palette.background);
    });

    testWidgets('undo and redo sit in the tools capsule', (tester) async {
      await pumpToolBar(tester);

      final tools = find.byType(ChromeCapsule).at(1);
      expect(
        find.descendant(of: tools, matching: undoButton()),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tools, matching: redoButton()),
        findsOneWidget,
      );
      expect(find.byType(ChromeDivider), findsOneWidget);
    });

    testWidgets('undo and redo follow history', (tester) async {
      final container = await pumpToolBar(tester);

      expect(tester.widget<ChromeIconButton>(undoButton()).enabled, isFalse);
      expect(tester.widget<ChromeIconButton>(redoButton()).enabled, isFalse);

      final stroke = Stroke.create(style: StrokeStyle.pen())
          .addPoint(DrawingPoint(x: 10, y: 10));
      container.read(historyManagerProvider.notifier).addStroke(stroke);
      await tester.pump();

      expect(tester.widget<ChromeIconButton>(undoButton()).enabled, isTrue);
      expect(tester.widget<ChromeIconButton>(redoButton()).enabled, isFalse);

      await tester.tap(undoButton());
      await tester.pump();

      expect(container.read(canUndoProvider), isFalse);
      expect(container.read(canRedoProvider), isTrue);
      expect(tester.widget<ChromeIconButton>(redoButton()).enabled, isTrue);

      await tester.tap(redoButton());
      await tester.pump();

      expect(container.read(canUndoProvider), isTrue);
      expect(container.read(canRedoProvider), isFalse);
    });

    testWidgets('has no horizontal scroll view', (tester) async {
      await pumpToolBar(tester);

      expect(
        find.descendant(
          of: find.byType(ToolBar),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
    });

    testWidgets('tool buttons are at least 48x48', (tester) async {
      await pumpToolBar(tester);

      final buttons = find.byType(ToolButton);
      expect(buttons, findsWidgets);
      for (final element in buttons.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('tapping a tool selects it', (tester) async {
      final container = await pumpToolBar(tester);

      await tester.tap(
        find.byIcon(ElyanotesIcons.iconForTool(ToolType.pixelEraser)),
      );
      await tester.pump();

      expect(eraserTools, contains(container.read(currentToolProvider)));
    });

    testWidgets('reader mode fades and ignores the tools capsule',
        (tester) async {
      final container = await pumpToolBar(tester);
      final tools = find.byType(ChromeCapsule).at(1);
      final fade = find.ancestor(
        of: tools,
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(fade).opacity, 1);

      container.read(readerModeProvider.notifier).state = true;
      await tester.pump();
      await tester.pump(ChromeDurations.instant);

      expect(tester.widget<AnimatedOpacity>(fade).opacity, 0);
      final ignoring = find.ancestor(
        of: tools,
        matching: find.byWidgetPredicate(_isIgnoring),
      );
      expect(ignoring, findsWidgets);

      // The other capsules stay in place.
      expect(find.byType(ChromeCapsule), findsNWidgets(3));
      expect(find.byIcon(ElyanotesIcons.home), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.readerModeActive), findsOneWidget);
    });
  });
}
