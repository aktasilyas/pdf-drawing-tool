import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/bootstrap/app_overrides.dart';
import 'package:example_app/core/config/feature_flags.dart';

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

  test('all flags on enables drawing_ui AI and audio entry points', () {
    final c = containerFor(FeatureFlags.allOn);
    expect(c.read(drawing_ui.aiAssistantEnabledProvider), isTrue);
    expect(c.read(drawing_ui.audioRecordingEnabledProvider), isTrue);
  });
}
