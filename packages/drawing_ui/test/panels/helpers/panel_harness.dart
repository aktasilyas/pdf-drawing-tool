import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../golden/helpers/chrome_theme.dart';

/// Pumps [panel] 380dp wide on the chrome theme and returns the container.
///
/// [setup] runs on the container before the first frame (select a tool, ...).
Future<ProviderContainer> pumpPanel(
  WidgetTester tester,
  Widget panel, {
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
  void Function(ProviderContainer container)? setup,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  setup?.call(container);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: chromeTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 380, child: panel),
          ),
        ),
      ),
    ),
  );
  return container;
}

/// Expects every widget matching [finder] to be at least 48x48.
void expectMinTapTarget(WidgetTester tester, Finder finder) {
  expect(finder, findsWidgets);
  for (final element in finder.evaluate()) {
    final size = (element.renderObject! as RenderBox).size;
    expect(size.width, greaterThanOrEqualTo(48), reason: '$finder width');
    expect(size.height, greaterThanOrEqualTo(48), reason: '$finder height');
  }
}
