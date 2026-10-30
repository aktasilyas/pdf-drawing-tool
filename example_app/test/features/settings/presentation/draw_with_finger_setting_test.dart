import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/settings/presentation/widgets/draw_with_finger_setting.dart';

import '../../../helpers/l10n.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Map<String, Object> initial = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: localizedApp(
          theme: AppTheme.light,
          home: const Scaffold(body: DrawWithFingerSetting()),
        ),
      ),
    );
    return ProviderScope.containerOf(
      tester.element(find.byType(DrawWithFingerSetting)),
    );
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch)).value;

  testWidgets('is on for finger-only users', (tester) async {
    await pump(tester);
    expect(switchValue(tester), isTrue);
  });

  testWidgets('is off once a stylus was detected', (tester) async {
    await pump(tester, initial: {'input_stylus_detected': true});
    expect(switchValue(tester), isFalse);
  });

  testWidgets('toggle persists the choice', (tester) async {
    final container =
        await pump(tester, initial: {'input_stylus_detected': true});
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(switchValue(tester), isTrue);
    expect(container.read(inputModeProvider).drawWithFinger, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('input_draw_with_finger'), isTrue);
  });
}
