import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/bootstrap/app_overrides.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/crash_reporting/crash_reporter.dart';
import 'package:example_app/core/crash_reporting/noop_crash_reporter.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer containerFor(FeatureFlags flags) {
    final c = ProviderContainer(
        overrides: buildAppOverrides(flags: flags, prefs: prefs));
    addTearDown(c.dispose);
    return c;
  }

  test('all flags off disables drawing_ui AI and audio entry points', () {
    final c = containerFor(FeatureFlags.allOff);
    expect(c.read(drawing_ui.aiAssistantEnabledProvider), isFalse);
    expect(c.read(drawing_ui.audioRecordingEnabledProvider), isFalse);
  });

  test('crash reporter defaults to no-op and can be overridden', () {
    final defaults = containerFor(FeatureFlags.allOff);
    expect(defaults.read(crashReporterProvider), isA<NoopCrashReporter>());

    const custom = NoopCrashReporter();
    final c = ProviderContainer(
      overrides: buildAppOverrides(
        flags: FeatureFlags.allOff,
        prefs: prefs,
        crashReporter: custom,
      ),
    );
    addTearDown(c.dispose);
    expect(c.read(crashReporterProvider), same(custom));
  });

  test('all flags on enables drawing_ui AI and audio entry points', () {
    final c = containerFor(FeatureFlags.allOn);
    expect(c.read(drawing_ui.aiAssistantEnabledProvider), isTrue);
    expect(c.read(drawing_ui.audioRecordingEnabledProvider), isTrue);
  });
}
