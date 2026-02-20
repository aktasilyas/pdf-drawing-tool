import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether zoom is currently locked (pinch zoom disabled, pan still works).
final zoomLockedProvider = StateProvider<bool>((ref) => false);

/// Favorite zoom percentages (relative to baselineZoom).
/// Default: [100, 150, 200].
final favoriteZoomsProvider =
    StateNotifierProvider<FavoriteZoomsNotifier, List<int>>(
  (ref) => FavoriteZoomsNotifier(),
);

/// Manages a persisted list of favorite zoom levels.
class FavoriteZoomsNotifier extends StateNotifier<List<int>> {
  FavoriteZoomsNotifier() : super([100, 150, 200]) {
    _load();
  }

  static const _key = 'favorite_zooms';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved != null && saved.isNotEmpty) {
      state = saved.map((s) => int.tryParse(s) ?? 100).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((z) => z.toString()).toList());
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
