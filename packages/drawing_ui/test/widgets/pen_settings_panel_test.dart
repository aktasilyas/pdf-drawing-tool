import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  double textScale = 1.0,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 380,
              child: PenSettingsPanel(toolType: ToolType.ballpointPen),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('has no stroke preview swoosh', (tester) async {
    await _pump(tester);
    final painters = tester
        .widgetList<CustomPaint>(find.descendant(
          of: find.byType(PenSettingsPanel),
          matching: find.byType(CustomPaint),
        ))
        .map((p) => p.painter.runtimeType.toString());
    expect(painters.where((n) => n.contains('Swoosh')), isEmpty);
  });

  testWidgets('has one PenTypePicker and three sliders', (tester) async {
    await _pump(tester);
    expect(find.byType(PenTypePicker), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
    expect(find.text('Kalınlık'), findsOneWidget);
    expect(find.textContaining('Uç Keskinliği'), findsNothing);
  });

  testWidgets('sliders show no step tick marks', (tester) async {
    await _pump(tester);
    for (final slider in tester.widgetList<Slider>(find.byType(Slider))) {
      expect(slider.divisions, isNull);
    }
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('does not overflow at width 380, textScaler $scale',
        (tester) async {
      await _pump(tester, textScale: scale);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PenSettingsPanel)).width, 380);
    });
  }

  testWidgets('sliders and close button have 48dp tap targets', (tester) async {
    await _pump(tester);
    final handle = tester.ensureSemantics();
    for (final slider in find.byType(Slider).evaluate()) {
      final box = find
          .ancestor(
            of: find.byWidget(slider.widget),
            matching: find.byType(SizedBox),
          )
          .first;
      expect(tester.getSize(box).height, greaterThanOrEqualTo(48));
    }
    final close = find.byTooltip('Kapat');
    expect(close, findsOneWidget);
    final size = tester.getSize(close);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    handle.dispose();
  });

  testWidgets('colour strip cells are 48dp', (tester) async {
    await _pump(tester);
    final add = find.byTooltip('Renk ekle');
    expect(add, findsOneWidget);
    expect(tester.getSize(add).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
  });
}
