import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/features/settings/domain/entities/app_settings.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

const _settingsKey = 'app_settings';

/// App-wide settings, read synchronously from the bootstrapped
/// [SharedPreferences] so the saved theme applies on the first frame
/// (no light-to-dark flash after a restart).
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(sharedPreferencesProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static AppSettings _load(SharedPreferences prefs) {
    final jsonString = prefs.getString(_settingsKey);
    if (jsonString == null) return const AppSettings();
    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return AppSettings.fromJson(decoded);
      }
    } on FormatException {
      // Corrupt value: fall back to defaults; the next save overwrites it.
    }
    return const AppSettings();
  }

  Future<void> _saveSettings() =>
      _prefs.setString(_settingsKey, json.encode(state.toJson()));

  Future<void> setTheme(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  Future<void> setPaperSize(PaperSize size) async {
    state = state.copyWith(defaultPaperSize: size);
    await _saveSettings();
  }

  Future<void> setAutoSave(bool enabled) async {
    state = state.copyWith(autoSaveEnabled: enabled);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }
}
