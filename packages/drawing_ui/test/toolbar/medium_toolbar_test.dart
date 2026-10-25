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

  Future<ProviderContainer> pumpToolBar(
    WidgetTester tester, {
    double width = 820,
    String? title,
  }) async {
    tester.view.physicalSize = Size(width, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: chromeTheme(Brightness.light),
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: Align(
                alignment: Alignment.topCenter,
                child: MediumToolbar(documentTitle: title),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return ProviderScope.containerOf(
        tester.element(find.byType(MediumToolbar)));
  }

  Finder undoButton() => find.byWidgetPredicate(
        (w) => w is ChromeIconButton && w.icon == ElyanotesIcons.undo,
      );

  Finder redoButton() => find.byWidgetPredicate(
        (w) => w is ChromeIconButton && w.icon == ElyanotesIcons.redo,
      );

  group('MediumToolbar at 820', () {
    testWidgets('nav has Home and Sidebar, no title', (tester) async {
      final container = await pumpToolBar(tester, title: 'Matematik notlari');
      container.read(pageManagerProvider.notifier).addPage();
      await tester.pump();

      expect(find.byType(ChromeCapsule), findsNWidgets(3));
      final nav = find.byType(ChromeCapsule).at(0);
      for (final icon in [ElyanotesIcons.home, ElyanotesIcons.sidebar]) {
        expect(
          find.descendant(of: nav, matching: find.byIcon(icon)),
          findsOneWidget,
        );
      }
      expect(find.byType(DocumentTitleButton), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('actions have Add page and More, Export is in More',
        (tester) async {
      final container = await pumpToolBar(tester);
      container.read(isInfiniteCanvasProvider.notifier).state = false;
      await tester.pump();

      final actions = find.byType(ChromeCapsule).at(2);
      for (final icon in [ElyanotesIcons.pageAdd, ElyanotesIcons.more]) {
        expect(
          find.descendant(of: actions, matching: find.byIcon(icon)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: actions,
          matching: find.byIcon(ElyanotesIcons.exportIcon),
        ),
        findsNothing,
      );
    });

    testWidgets('fits at least 8 tools without overflowing', (tester) async {
      await pumpToolBar(tester);

      final tools = find.byType(ChromeCapsule).at(1);
      final shown =
          find.descendant(of: tools, matching: find.byType(ToolButton));
      expect(shown.evaluate().length, greaterThanOrEqualTo(8));
      expect(tester.takeException(), isNull);
    });

    testWidgets('collapses extra tools into the overflow menu at 600',
        (tester) async {
      await pumpToolBar(tester, width: 600);

      expect(find.byType(ToolbarOverflowMenu), findsOneWidget);
      expect(tester.takeException(), isNull);
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

    testWidgets('has no horizontal scroll view', (tester) async {
      await pumpToolBar(tester);

      expect(
        find.descendant(
          of: find.byType(MediumToolbar),
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

    testWidgets('reader mode fades the tools capsule only', (tester) async {
      final container = await pumpToolBar(tester);
      final tools = find.byType(ChromeCapsule).at(1);
      final fade = find.ancestor(
        of: tools,
        matching: find.byType(AnimatedOpacity),
      );

      container.read(readerModeProvider.notifier).state = true;
      await tester.pump();
      await tester.pump(ChromeDurations.instant);

      expect(tester.widget<AnimatedOpacity>(fade).opacity, 0);
      expect(
        find.ancestor(
          of: tools,
          matching: find.byWidgetPredicate(_isIgnoring),
        ),
        findsWidgets,
      );
      expect(find.byType(ChromeCapsule), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('MediumToolbar at 600', () {
    testWidgets('does not overflow with long title and pages', (tester) async {
      final container = await pumpToolBar(
        tester,
        width: 600,
        title: 'Cok uzun belge basligi: matematik ve fizik ders notlari 2026',
      );
      container.read(pageManagerProvider.notifier).addPage();
      container.read(isInfiniteCanvasProvider.notifier).state = false;
      await tester.pump();

      expect(find.byIcon(ElyanotesIcons.sidebar), findsOneWidget);
      expect(find.byType(ChromeCapsule), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow in reader mode', (tester) async {
      final container = await pumpToolBar(tester, width: 600);
      container.read(readerModeProvider.notifier).state = true;
      await tester.pump();
      await tester.pump(ChromeDurations.instant);

      expect(tester.takeException(), isNull);
    });
  });
}
