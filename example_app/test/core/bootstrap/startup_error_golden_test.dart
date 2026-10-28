import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/bootstrap/startup_error_app.dart';

import '../../helpers/font_loader.dart';

const _phone = Size(390, 844);
const _tablet = Size(1180, 820);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
  });

  final cases = [
    ('startup_error_phone_light', _phone, ThemeMode.light),
    ('startup_error_phone_dark', _phone, ThemeMode.dark),
    ('startup_error_tablet_light', _tablet, ThemeMode.light),
  ];

  for (final (name, size, mode) in cases) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        StartupErrorApp(
          onRetry: () {},
          themeMode: mode,
          locale: const Locale('tr'),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }
}
