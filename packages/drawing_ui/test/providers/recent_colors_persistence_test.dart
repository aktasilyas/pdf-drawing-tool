import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

  test('colours survive a provider container rebuild in order', () {
    final first = makeContainer();
    final notifier = first.read(recentColorsProvider.notifier);
    notifier.addColor(const Color(0xFFFF0000));
    notifier.addColor(const Color(0xFF00FF00));
    first.dispose();

    final second = makeContainer();
    addTearDown(second.dispose);
    expect(second.read(recentColorsProvider), const [
      Color(0xFF00FF00),
      Color(0xFFFF0000),
    ]);
  });

  test('stores at most six entries', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final notifier = c.read(recentColorsProvider.notifier);
    for (var i = 0; i < 9; i++) {
      notifier.addColor(Color(0xFF000000 | (i + 1) * 0x10));
    }
    expect(prefs.getStringList('elyanotes_recent_colors')!.length, 6);
  });

  test('corrupt stored value loads as empty list', () {
    prefs.setStringList('elyanotes_recent_colors', ['abc', '']);
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(recentColorsProvider), isEmpty);
  });

  test('null prefs behave as in-memory', () {
    final notifier = RecentColorsNotifier(null);
    notifier.addColor(const Color(0xFF123456));
    expect(notifier.state, const [Color(0xFF123456)]);
  });
}
