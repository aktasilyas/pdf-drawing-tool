import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('LassoSettingsNotifier', () {
    test('starts from defaults without prefs', () {
      final notifier = LassoSettingsNotifier(null);
      expect(notifier.state.mode, LassoSettings.defaultSettings().mode);
    });

    test('setAllSelectableTypes toggles every type', () {
      final notifier = LassoSettingsNotifier(null);
      notifier.setAllSelectableTypes(false);
      expect(notifier.state.selectableTypes.values.every((v) => !v), isTrue);
      notifier.setAllSelectableTypes(true);
      expect(notifier.state.selectableTypes.values.every((v) => v), isTrue);
    });

    test('persists and reloads settings', () async {
      final notifier = LassoSettingsNotifier(prefs);
      notifier.setMode(LassoMode.rectangle);
      await Future<void>.delayed(Duration.zero);
      expect(LassoSettingsNotifier(prefs).state.mode, LassoMode.rectangle);
    });
  });

  group('LaserSettingsNotifier', () {
    test('starts from defaults without prefs', () {
      final notifier = LaserSettingsNotifier(null);
      expect(notifier.state.mode, LaserSettings.defaultSettings().mode);
    });

    test('persists and reloads settings', () async {
      final notifier = LaserSettingsNotifier(prefs);
      notifier.setColor(Colors.green);
      notifier.setThickness(7);
      await Future<void>.delayed(Duration.zero);
      final reloaded = LaserSettingsNotifier(prefs).state;
      expect(reloaded.color.toARGB32(), Colors.green.toARGB32());
      expect(reloaded.thickness, 7);
    });
  });
}
