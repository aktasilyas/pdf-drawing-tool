import 'package:drawing_ui/drawing_ui.dart' show sharedPreferencesProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';

// The library view preferences read the injected [SharedPreferences]
// synchronously, so the first frame already uses the stored choice and a
// change made right after start is never overwritten. Null prefs (tests,
// no bootstrap) keep the choice in memory with the defaults.

/// Stored enum [name] for [key], or [fallback] when missing or unknown.
T _readEnum<T extends Enum>(
  SharedPreferences? prefs,
  String key,
  List<T> values,
  T fallback,
) {
  final stored = prefs?.getString(key);
  if (stored == null) return fallback;
  for (final value in values) {
    if (value.name == stored) return value;
  }
  return fallback;
}

// View mode (grid/list) with persistence
final viewModeProvider =
    StateNotifierProvider<ViewModeNotifier, ViewMode>((ref) {
  return ViewModeNotifier(ref.watch(sharedPreferencesProvider));
});

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier(this._prefs)
      : super(_readEnum(
          _prefs,
          StorageKeys.viewMode,
          ViewMode.values,
          ViewMode.grid,
        ));

  final SharedPreferences? _prefs;

  Future<void> set(ViewMode mode) async {
    state = mode;
    await _prefs?.setString(StorageKeys.viewMode, mode.name);
  }
}

// Sort option (date/name/size) with persistence
final sortOptionProvider =
    StateNotifierProvider<SortOptionNotifier, SortOption>((ref) {
  return SortOptionNotifier(ref.watch(sharedPreferencesProvider));
});

class SortOptionNotifier extends StateNotifier<SortOption> {
  SortOptionNotifier(this._prefs)
      : super(_readEnum(
          _prefs,
          StorageKeys.sortOption,
          SortOption.values,
          SortOption.date,
        ));

  final SharedPreferences? _prefs;

  Future<void> set(SortOption option) async {
    state = option;
    await _prefs?.setString(StorageKeys.sortOption, option.name);
  }
}

// Sort direction (ascending/descending) with persistence
final sortDirectionProvider =
    StateNotifierProvider<SortDirectionNotifier, SortDirection>((ref) {
  return SortDirectionNotifier(ref.watch(sharedPreferencesProvider));
});

class SortDirectionNotifier extends StateNotifier<SortDirection> {
  SortDirectionNotifier(this._prefs)
      : super(_readEnum(
          _prefs,
          StorageKeys.sortDirection,
          SortDirection.values,
          SortDirection.descending,
        ));

  final SharedPreferences? _prefs;

  Future<void> set(SortDirection direction) async {
    state = direction;
    await _prefs?.setString(StorageKeys.sortDirection, direction.name);
  }
}

// Pin favorites to top with persistence
final pinFavoritesProvider =
    StateNotifierProvider<PinFavoritesNotifier, bool>((ref) {
  return PinFavoritesNotifier(ref.watch(sharedPreferencesProvider));
});

class PinFavoritesNotifier extends StateNotifier<bool> {
  PinFavoritesNotifier(this._prefs) : super(_readBool(_prefs));

  final SharedPreferences? _prefs;

  /// Stored flag; a missing or non-bool value falls back to false.
  static bool _readBool(SharedPreferences? prefs) {
    final stored = prefs?.get(StorageKeys.pinFavoritesToTop);
    return stored is bool ? stored : false;
  }

  Future<void> toggle() => set(!state);

  Future<void> set(bool value) async {
    state = value;
    await _prefs?.setBool(StorageKeys.pinFavoritesToTop, value);
  }
}
