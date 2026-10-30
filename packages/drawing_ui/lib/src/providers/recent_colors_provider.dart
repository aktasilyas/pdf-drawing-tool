import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// SharedPreferences key holding the recent colours as ARGB ints.
const _recentColorsKey = 'elyanotes_recent_colors';

/// Recently used colours manager (max 6), persisted across app restarts.
class RecentColorsNotifier extends StateNotifier<List<Color>> {
  RecentColorsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences? _prefs;

  /// Maximum number of colours kept.
  static const int maxColors = 6;

  static List<Color> _load(SharedPreferences? prefs) {
    if (prefs == null) return [];
    try {
      final stored = prefs.getStringList(_recentColorsKey);
      if (stored == null) return [];
      return stored
          .map((s) => Color(int.parse(s)))
          .take(maxColors)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  set state(List<Color> value) {
    super.state = value;
    _prefs?.setStringList(
      _recentColorsKey,
      value.map((c) => c.toARGB32().toString()).toList(),
    );
  }

  /// Adds a colour at the front, removing any duplicate first.
  void addColor(Color color) {
    // Drop the same colour if present (RGB comparison)
    final filtered = state
        .where((c) =>
            (c.r * 255.0).round().clamp(0, 255) !=
                (color.r * 255.0).round().clamp(0, 255) ||
            (c.g * 255.0).round().clamp(0, 255) !=
                (color.g * 255.0).round().clamp(0, 255) ||
            (c.b * 255.0).round().clamp(0, 255) !=
                (color.b * 255.0).round().clamp(0, 255))
        .toList();

    // Prepend and cap at the maximum
    state = [color, ...filtered].take(maxColors).toList();
  }

  /// Removes a specific colour.
  void removeColor(Color color) {
    state = state
        .where((c) =>
            (c.r * 255.0).round().clamp(0, 255) !=
                (color.r * 255.0).round().clamp(0, 255) ||
            (c.g * 255.0).round().clamp(0, 255) !=
                (color.g * 255.0).round().clamp(0, 255) ||
            (c.b * 255.0).round().clamp(0, 255) !=
                (color.b * 255.0).round().clamp(0, 255))
        .toList();
  }

  /// Clears all colours.
  void clear() {
    state = [];
  }
}

/// Recent colours provider.
final recentColorsProvider =
    StateNotifierProvider<RecentColorsNotifier, List<Color>>(
  (ref) => RecentColorsNotifier(ref.watch(sharedPreferencesProvider)),
);
