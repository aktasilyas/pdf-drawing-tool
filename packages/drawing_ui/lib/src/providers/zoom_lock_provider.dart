import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// Whether zoom is currently locked (pinch zoom disabled, pan still works).
final zoomLockedProvider = StateProvider<bool>((ref) => false);

/// Default favorite zoom percentages.
const List<int> kDefaultFavoriteZooms = [100, 150, 200];

/// Favorite zoom percentages (relative to baselineZoom).
/// Persisted through [sharedPreferencesProvider]; memory-only when it is null.
final favoriteZoomsProvider =
    StateNotifierProvider<FavoriteZoomsNotifier, List<int>>(
  (ref) => FavoriteZoomsNotifier(ref.watch(sharedPreferencesProvider)),
);

/// Manages a persisted list of favorite zoom levels.
class FavoriteZoomsNotifier extends StateNotifier<List<int>> {
  FavoriteZoomsNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences? _prefs;

  static const _key = 'favorite_zooms';

  static List<int> _read(SharedPreferences? prefs) {
    final saved = prefs?.getStringList(_key);
    if (saved == null) return kDefaultFavoriteZooms;
    final zooms = saved
        .map(int.tryParse)
        .whereType<int>()
        .where((z) => z > 0)
        .toSet()
        .toList()
      ..sort();
    return zooms.isEmpty ? kDefaultFavoriteZooms : zooms;
  }

  void _save() {
    _prefs?.setStringList(_key, state.map((z) => z.toString()).toList());
  }

  void addFavorite(int zoomPercent) {
    if (!state.contains(zoomPercent)) {
      state = [...state, zoomPercent]..sort();
      _save();
    }
  }

  void removeFavorite(int zoomPercent) {
    state = state.where((z) => z != zoomPercent).toList();
    _save();
  }

  void toggleFavorite(int zoomPercent) {
    if (state.contains(zoomPercent)) {
      removeFavorite(zoomPercent);
    } else {
      addFavorite(zoomPercent);
    }
  }
}
