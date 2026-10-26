import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/features/settings/domain/entities/app_settings.dart';
import 'package:example_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

Future<ProviderContainer> _container(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('defaults to system theme when nothing is saved', () async {
    final c = await _container({});
    expect(c.read(settingsProvider).themeMode, AppThemeMode.system);
  });

  test('saved theme is available synchronously on first read (restart)',
      () async {
    final c = await _container({
      'app_settings': json.encode({'themeMode': 'dark'}),
    });
    expect(c.read(settingsProvider).themeMode, AppThemeMode.dark);
  });

  test('setTheme updates state and persists it', () async {
    final c = await _container({});
    await c.read(settingsProvider.notifier).setTheme(AppThemeMode.light);
    expect(c.read(settingsProvider).themeMode, AppThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    final saved = json.decode(prefs.getString('app_settings')!) as Map;
    expect(saved['themeMode'], 'light');

    // A fresh container (app restart) reads the saved value.
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    expect(restarted.read(settingsProvider).themeMode, AppThemeMode.light);
  });

  test('corrupt saved value falls back to defaults', () async {
    final c = await _container({'app_settings': 'not json {'});
    expect(c.read(settingsProvider), const AppSettings());
  });

  test('non-object JSON falls back to defaults', () async {
    final c = await _container({'app_settings': '[1, 2]'});
    expect(c.read(settingsProvider), const AppSettings());
  });
}
