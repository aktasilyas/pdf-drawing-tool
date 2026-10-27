import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {ProviderContainer? container}) {
  final app =
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
}

void main() {
  group('PageOptionsMenuItem', () {
    testWidgets('tap calls back', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(PageOptionsMenuItem(
        icon: ElyanotesIcons.sliders,
        label: 'Row',
        onTap: () => taps++,
      )));
      await tester.tap(find.text('Row'));
      expect(taps, 1);
    });

    testWidgets('is at least 48dp tall in regular mode', (tester) async {
      await tester.pumpWidget(_host(PageOptionsMenuItem(
        icon: ElyanotesIcons.sliders,
        label: 'Row',
        onTap: () {},
      )));
      expect(tester.getSize(find.byType(PageOptionsMenuItem)).height,
          greaterThanOrEqualTo(48));
    });
  });

  group('PageOptionsToggleItem', () {
    testWidgets('toggling reports the new value', (tester) async {
      bool? changed;
      await tester.pumpWidget(_host(PageOptionsToggleItem(
        icon: ElyanotesIcons.sliders,
        label: 'Toggle',
        value: false,
        onChanged: (v) => changed = v,
      )));
      await tester.tap(find.byType(Switch));
      expect(changed, isTrue);
    });

    testWidgets('disabled switch ignores taps', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(PageOptionsToggleItem(
        icon: ElyanotesIcons.sliders,
        label: 'Toggle',
        value: false,
        onChanged: (_) => calls++,
      )));
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.onChanged, isNotNull);
      // Rebuild with the switch disabled through a wrapping IgnorePointer.
      await tester.pumpWidget(_host(IgnorePointer(
        child: PageOptionsToggleItem(
          icon: ElyanotesIcons.sliders,
          label: 'Toggle',
          value: false,
          onChanged: (_) => calls++,
        ),
      )));
      await tester.tap(find.byType(Switch), warnIfMissed: false);
      expect(calls, 0);
    });

    testWidgets('is at least 48dp tall', (tester) async {
      await tester.pumpWidget(_host(PageOptionsToggleItem(
        icon: ElyanotesIcons.sliders,
        label: 'Toggle',
        value: true,
        onChanged: (_) {},
      )));
      expect(tester.getSize(find.byType(PageOptionsToggleItem)).height,
          greaterThanOrEqualTo(48));
    });
  });

  testWidgets('ScrollDirectionItem switches scrollDirectionProvider',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(scrollDirectionProvider), Axis.horizontal);
    await tester.pumpWidget(
        _host(ScrollDirectionItem(onClose: () {}), container: container));
    expect(find.text('Yatay'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(container.read(scrollDirectionProvider), Axis.vertical);
    expect(find.text('Dikey'), findsOneWidget);
  });

  testWidgets('panel has no overflow at textScaler 1.3 on a 360dp phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(body: PageOptionsPanel(onClose: () {})),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
