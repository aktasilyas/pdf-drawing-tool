import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/core/crash_reporting/crash_reporter.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/settings/presentation/widgets/crash_reporting_setting.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

class _MockReporter extends Mock implements CrashReporter {}

void main() {
  late _MockReporter reporter;

  setUp(() {
    reporter = _MockReporter();
    when(() => reporter.setCollectionEnabled(any())).thenAnswer((_) async {});
  });

  Future<SharedPreferences> pump(
    WidgetTester tester, {
    Map<String, Object> initial = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          crashReporterProvider.overrideWithValue(reporter),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: CrashReportingSetting()),
        ),
      ),
    );
    return prefs;
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch)).value;

  testWidgets('is on by default and shows the copy', (tester) async {
    await pump(tester);
    expect(switchValue(tester), isTrue);
    expect(find.text('Çökme raporlarını gönder'), findsOneWidget);
    expect(
      find.text('Anonim hata raporları; not içeriği gönderilmez'),
      findsOneWidget,
    );
  });

  testWidgets('renders off when the stored value is false', (tester) async {
    await pump(tester, initial: {StorageKeys.crashReportingEnabled: false});
    expect(switchValue(tester), isFalse);
  });

  testWidgets('tapping persists the choice and tells the reporter',
      (tester) async {
    final prefs = await pump(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(switchValue(tester), isFalse);
    expect(prefs.getBool(StorageKeys.crashReportingEnabled), isFalse);
    verify(() => reporter.setCollectionEnabled(false)).called(1);
  });
}
