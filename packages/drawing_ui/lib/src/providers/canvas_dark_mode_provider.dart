import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// SharedPreferences key for canvas dark mode setting.
const _canvasDarkModeKey = 'canvas_dark_mode';

/// Canvas dark mode setting.
enum CanvasDarkMode {
  /// Always light canvas (default — current behavior).
  off,

  /// Always dark canvas.
  on,

  /// Follow system theme.
  followSystem,
}

/// System brightness provider — override from DrawingScreen with
/// `MediaQuery.platformBrightnessOf(context)`.
final platformBrightnessProvider = StateProvider<Brightness>((ref) {
  return Brightness.light;
});

/// Persisted canvas dark mode setting.
///
/// Reads initial value from SharedPreferences on creation.
/// Writes to SharedPreferences on every change via [setCanvasDarkMode].
final canvasDarkModeProvider =
    StateNotifierProvider<CanvasDarkModeNotifier, CanvasDarkMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CanvasDarkModeNotifier(prefs);
});

/// Notifier that persists [CanvasDarkMode] to SharedPreferences.
class CanvasDarkModeNotifier extends StateNotifier<CanvasDarkMode> {
  CanvasDarkModeNotifier(this._prefs) : super(_load(_prefs));

  final dynamic _prefs; // SharedPreferences?

  static CanvasDarkMode _load(dynamic prefs) {
    if (prefs == null) return CanvasDarkMode.off;
    try {
      final saved = (prefs as dynamic).getString(_canvasDarkModeKey) as String?;
      if (saved != null) {
        return CanvasDarkMode.values.byName(saved);
      }
    } catch (_) {
      // Invalid value or no prefs — use default
    }
    return CanvasDarkMode.off;
  }

  /// Update the dark mode setting and persist it.
  Future<void> setMode(CanvasDarkMode mode) async {
    state = mode;
    if (_prefs != null) {
      await (_prefs as dynamic).setString(_canvasDarkModeKey, mode.name);
    }
  }
}

/// Resolved canvas color scheme based on dark mode setting + system brightness.
///
/// Consumers (painters, widgets) watch this to get the active color scheme.
final canvasColorSchemeProvider = Provider<CanvasColorScheme>((ref) {
  final mode = ref.watch(canvasDarkModeProvider);
  final brightness = ref.watch(platformBrightnessProvider);

  switch (mode) {
    case CanvasDarkMode.off:
      return CanvasColorScheme.light();
    case CanvasDarkMode.on:
      return CanvasColorScheme.dark();
    case CanvasDarkMode.followSystem:
      return brightness == Brightness.dark
          ? CanvasColorScheme.dark()
          : CanvasColorScheme.light();
  }
});
