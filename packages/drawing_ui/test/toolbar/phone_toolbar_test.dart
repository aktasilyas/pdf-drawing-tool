import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/toolbar/phone_nav_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../golden/helpers/chrome_theme.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> pumpPhone(
    WidgetTester tester, {
    double width = 390,
    String? title,
    ValueChanged<ToolType>? onPanelRequested,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // v1.0 configuration: audio recording is frozen.
          audioRecordingEnabledProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          theme: chromeTheme(Brightness.light),
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: Align(
                alignment: Alignment.topCenter,
                child: AdaptiveToolbar(
                  documentTitle: title,
                  onToolPanelRequested: onPanelRequested,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return ProviderScope.containerOf(
        tester.element(find.byType(AdaptiveToolbar)));
  }

  Finder inNav(Finder f) =>
      find.descendant(of: find.byType(PhoneNavRow), matching: f);

  Finder inTools(Finder f) =>
      find.descendant(of: find.byType(CompactToolRow), matching: f);

  group('Phone toolbar at 390', () {
    testWidgets('chrome is 104 tall: 48 nav row + tool capsule row',
        (tester) async {
      await pumpPhone(tester);

      expect(tester.getSize(find.byType(PhoneNavRow)).height, 48);
      expect(tester.getSize(find.byType(AdaptiveToolbar)).height, 104);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nav row: Back, serif title, More; no Export or Add page',
        (tester) async {
      await pumpPhone(tester, title: 'Matematik notlari');

      expect(inNav(find.byIcon(ElyanotesIcons.home)), findsOneWidget);
      expect(inNav(find.text('Matematik notlari')), findsOneWidget);
      expect(inNav(find.byIcon(ElyanotesIcons.more)), findsOneWidget);
      expect(find.byIcon(ElyanotesIcons.exportIcon), findsNothing);
      expect(find.byIcon(ElyanotesIcons.pageAdd), findsNothing);
      // No tools in the nav row any more; they all live in the capsule.
      expect(inNav(find.byType(ToolButton)), findsNothing);
    });

    testWidgets('title uses the titleLarge (serif) family', (tester) async {
      await pumpPhone(tester, title: 'Matematik notlari');

      final context = tester.element(find.byType(PhoneNavRow));
      final text = tester.widget<Text>(inNav(find.text('Matematik notlari')));
      expect(
        text.style?.fontFamily,
        Theme.of(context).textTheme.titleLarge?.fontFamily,
      );
      expect(text.maxLines, 1);
    });

    testWidgets('Pages button appears only for multi-page documents',
        (tester) async {
      final container = await pumpPhone(tester);
      expect(inNav(find.byIcon(ElyanotesIcons.sidebar)), findsNothing);

      container.read(pageManagerProvider.notifier).addPage();
      await tester.pump();
      expect(inNav(find.byIcon(ElyanotesIcons.sidebar)), findsOneWidget);
    });

    testWidgets('tool row is one capsule with undo, redo and tools',
        (tester) async {
      await pumpPhone(tester);

      expect(inTools(find.byType(ChromeCapsule)), findsOneWidget);
      expect(inTools(find.byIcon(ElyanotesIcons.undo)), findsOneWidget);
      expect(inTools(find.byIcon(ElyanotesIcons.redo)), findsOneWidget);
      expect(inTools(find.byType(ChromeDivider)), findsOneWidget);
      expect(inTools(find.byType(ToolButton)), findsWidgets);
      expect(inTools(find.byType(Scrollable)), findsNothing);
    });

    testWidgets('extra tools collapse into one overflow slot', (tester) async {
      await pumpPhone(tester);

      final config = ProviderScope.containerOf(
              tester.element(find.byType(AdaptiveToolbar)))
          .read(toolbarConfigProvider);
      final total = getGroupedVisibleTools(config, ToolType.ballpointPen);
      final shown = tester.widgetList(inTools(find.byType(ToolButton))).length;
      final overflow = inTools(find.byType(ToolbarOverflowMenu));

      if (shown < total.length) {
        expect(overflow, findsOneWidget);
      } else {
        expect(overflow, findsNothing);
      }
      // The capsule stays inside the 8dp side margins.
      final capsule = tester.getRect(inTools(find.byType(ChromeCapsule)));
      expect(capsule.left, greaterThanOrEqualTo(ChromeSpacing.sm));
      expect(capsule.right, lessThanOrEqualTo(390 - ChromeSpacing.sm));
    });

    testWidgets('every chrome button keeps a 48x48 hit area',
        (tester) async {
      final container = await pumpPhone(tester);
      container.read(pageManagerProvider.notifier).addPage();
      await tester.pump();

      for (final element in find.byType(ChromeIconButton).evaluate()) {
        expect(element.size!.width,
            greaterThanOrEqualTo(ChromeSizes.minTouchTarget));
        expect(element.size!.height,
            greaterThanOrEqualTo(ChromeSizes.minTouchTarget));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the selected pen requests its panel',
        (tester) async {
      ToolType? requested;
      await pumpPhone(tester, onPanelRequested: (t) => requested = t);

      final pen = inTools(find.byWidgetPredicate(
        (w) => w is ToolButton && w.toolType == ToolType.ballpointPen,
      ));
      expect(pen, findsOneWidget);
      await tester.tap(pen);
      await tester.pump();
      await tester.tap(pen);
      await tester.pump();

      expect(requested, ToolType.ballpointPen);
    });

    testWidgets('reader mode hides the tool row, Reader stays active',
        (tester) async {
      final container = await pumpPhone(tester);
      container.read(readerModeProvider.notifier).state = true;
      await tester.pump();

      expect(find.byType(ChromeCapsule), findsNothing);
      expect(
          inNav(find.byIcon(ElyanotesIcons.readerModeActive)), findsOneWidget);
      expect(inNav(find.byIcon(ElyanotesIcons.ruler)), findsNothing);
      expect(tester.getSize(find.byType(AdaptiveToolbar)).height, 48);
    });
  });

  testWidgets('no overflow on a 320 wide phone', (tester) async {
    final container = await pumpPhone(tester, width: 320, title: 'Uzun bir '
        'defter basligi ki tek satira sigmasin diye yazildi');
    container.read(pageManagerProvider.notifier).addPage();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(inTools(find.byType(ToolbarOverflowMenu)), findsOneWidget);
  });
}
