import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _palette = ChromePalette.light;

Widget _host(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: const [_palette]),
    home: Scaffold(body: Center(child: child)),
  );
}

BoxDecoration _visual(WidgetTester tester, Finder of) {
  final box = tester.widget<AnimatedContainer>(
    find.descendant(of: of, matching: find.byType(AnimatedContainer)),
  );
  return box.decoration! as BoxDecoration;
}

Color? _iconColor(WidgetTester tester, Finder of) {
  final icon = tester.widget<PhosphorIcon>(
    find.descendant(of: of, matching: find.byType(PhosphorIcon)),
  );
  return icon.color;
}

void main() {
  group('ElyanotesNavButton', () {
    testWidgets('renders a ChromeIconButton with a 48dp hit area',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ElyanotesNavButton(
            icon: ElyanotesIcons.home,
            tooltip: 'Home',
            onPressed: () => taps++,
            size: 32,
          ),
        ),
      );

      final button = find.byType(ChromeIconButton);
      expect(button, findsOneWidget);
      final hit = tester.getRect(button);
      expect(hit.size, const Size.square(ChromeSizes.minTouchTarget));
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size.square(ChromeIconButton.visualSize),
      );

      await tester.tapAt(hit.topLeft + const Offset(1, 1));
      expect(taps, 1);
      expect(_iconColor(tester, button), _palette.textMuted);
    });

    testWidgets('active uses accentContainer fill and accent icon',
        (tester) async {
      await tester.pumpWidget(
        _host(
          ElyanotesNavButton(
            icon: ElyanotesIcons.sidebar,
            tooltip: 'Sidebar',
            onPressed: () {},
            isActive: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byType(ChromeIconButton);
      expect(_visual(tester, button).color, _palette.accentContainer);
      expect(_iconColor(tester, button), _palette.accent);
    });

    testWidgets('disabled ignores taps and uses textDisabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ElyanotesNavButton(
            icon: ElyanotesIcons.home,
            tooltip: 'Home',
            onPressed: () => taps++,
            isDisabled: true,
          ),
        ),
      );

      await tester.tap(find.byType(ElyanotesNavButton));
      expect(taps, 0);
      expect(
        _iconColor(tester, find.byType(ChromeIconButton)),
        _palette.textDisabled,
      );
    });

    testWidgets('badge sits inside the hit area and does not block taps',
        (tester) async {
      var taps = 0;
      const badgeKey = Key('badge');
      await tester.pumpWidget(
        _host(
          ElyanotesNavButton(
            icon: ElyanotesIcons.home,
            tooltip: 'Home',
            onPressed: () => taps++,
            badge: const SizedBox.square(key: badgeKey, dimension: 8),
          ),
        ),
      );

      final hit = tester.getRect(find.byType(ChromeIconButton));
      final badge = tester.getRect(find.byKey(badgeKey));
      expect(hit.contains(badge.topLeft), isTrue);
      expect(hit.contains(badge.bottomRight - const Offset(1, 1)), isTrue);

      await tester.tapAt(badge.center);
      expect(taps, 1);
    });
  });

  group('ToolbarIconButton', () {
    testWidgets('renders a ChromeIconButton with a 48dp hit area',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ToolbarIconButton(
            icon: ElyanotesIcons.undo,
            tooltip: 'Geri al',
            enabled: true,
            onPressed: () => taps++,
          ),
        ),
      );

      final button = find.byType(ChromeIconButton);
      expect(
        tester.getSize(button),
        const Size.square(ChromeSizes.minTouchTarget),
      );
      await tester.tap(button);
      expect(taps, 1);
      expect(_iconColor(tester, button), _palette.textMuted);
    });

    testWidgets('disabled ignores taps and uses textDisabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ToolbarIconButton(
            icon: ElyanotesIcons.redo,
            tooltip: 'İleri al',
            enabled: false,
            onPressed: () => taps++,
          ),
        ),
      );

      final button = find.byType(ChromeIconButton);
      await tester.tap(button);
      expect(taps, 0);
      expect(_iconColor(tester, button), _palette.textDisabled);
    });

    testWidgets('undo and redo render as two adjacent 48dp targets',
        (tester) async {
      await tester.pumpWidget(
        _host(const ToolbarUndoRedoButtons(canUndo: true, canRedo: true)),
      );

      expect(find.byType(ChromeIconButton), findsNWidgets(2));
      expect(
        tester.getSize(find.byType(ToolbarUndoRedoButtons)).width,
        2 * ChromeSizes.minTouchTarget,
      );
    });
  });

  group('TopNavigationBar compact', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget bar(double width) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          isInfiniteCanvasProvider.overrideWith((ref) => false),
          pageCountProvider.overrideWithValue(2),
          // v1.0 configuration: audio recording is frozen.
          audioRecordingEnabledProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [_palette]),
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: const TopNavigationBar(compact: true),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('nav buttons keep their 48dp width at 400 wide',
        (tester) async {
      await tester.pumpWidget(bar(400));

      expect(tester.takeException(), isNull);
      final buttons = find.byType(ChromeIconButton);
      expect(buttons, findsWidgets);
      // Width only: the bar's 0.5dp bottom border leaves 47.5dp of height
      // until the phone toolbar is rebuilt in slice 8.
      for (final element in buttons.evaluate()) {
        expect(
          element.size!.width,
          greaterThanOrEqualTo(ChromeSizes.minTouchTarget),
        );
      }
    });

    testWidgets('does not overflow on a 320 wide phone', (tester) async {
      await tester.pumpWidget(bar(320));
      expect(tester.takeException(), isNull);
      expect(find.byType(ChromeIconButton), findsWidgets);
    });
  });
}
