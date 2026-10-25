import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';

// View mode (grid/list) with persistence
final viewModeProvider =
    StateNotifierProvider<ViewModeNotifier, ViewMode>((ref) {
  return ViewModeNotifier();
});

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier() : super(ViewMode.grid) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.viewMode);
    if (value != null) {
      final mode = ViewMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ViewMode.grid,
      );
      state = mode;
    }
  }

  Future<void> set(ViewMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.viewMode, mode.name);
  }
}

// Sort option (date/name/size) with persistence
final sortOptionProvider =
    StateNotifierProvider<SortOptionNotifier, SortOption>((ref) {
  return SortOptionNotifier();
});

class SortOptionNotifier extends StateNotifier<SortOption> {
  SortOptionNotifier() : super(SortOption.date) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.sortOption);
    if (value != null) {
      final option = SortOption.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SortOption.date,
      );
      state = option;
    }
  }

  Future<void> set(SortOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.sortOption, option.name);
  }
}

// Sort direction (ascending/descending) with persistence
final sortDirectionProvider =
    StateNotifierProvider<SortDirectionNotifier, SortDirection>((ref) {
  return SortDirectionNotifier();
});

class SortDirectionNotifier extends StateNotifier<SortDirection> {
  SortDirectionNotifier() : super(SortDirection.descending) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.sortDirection);
    if (value != null) {
      final direction = SortDirection.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SortDirection.descending,
      );
      state = direction;
    }
  }

  Future<void> set(SortDirection direction) async {
    state = direction;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.sortDirection, direction.name);
  }
}

// Pin favorites to top with persistence
final pinFavoritesProvider =
    StateNotifierProvider<PinFavoritesNotifier, bool>((ref) {
  return PinFavoritesNotifier();
});

class PinFavoritesNotifier extends StateNotifier<bool> {
  PinFavoritesNotifier() : super(false) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(StorageKeys.pinFavoritesToTop);
    if (value != null) {
      state = value;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.pinFavoritesToTop, state);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.pinFavoritesToTop, value);
  }
}
