import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/bootstrap/startup_error_app.dart';

void main() {
  for (final (locale, title, retry) in [
    (const Locale('tr'), 'Uygulama başlatılamadı', 'Tekrar dene'),
    (const Locale('en'), "The app couldn't start", 'Try again'),
  ]) {
    testWidgets('follows the $locale locale at text scale 1.3', (tester) async {
      tester.view.physicalSize = const Size(380, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(
        StartupErrorApp(onRetry: () {}, locale: locale),
      );
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);
      expect(find.text(retry), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('follows the device locale when none is pinned', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(StartupErrorApp(onRetry: () {}));
    await tester.pumpAndSettle();

    expect(find.text("The app couldn't start"), findsOneWidget);
  });
}
