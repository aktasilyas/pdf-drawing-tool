import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

/// Key for storing toolbar config in SharedPreferences
const _toolbarConfigKey = 'starnote_toolbar_config';

/// Provider for SharedPreferences instance for toolbar config
/// 
/// This provider can be overridden by the host app to enable persistence:
/// 
/// ```dart
/// ProviderScope(
///   overrides: [
///     sharedPreferencesProvider.overrideWithValue(prefs),
///   ],
///   child: MyApp(),
/// )
/// ```
/// 
/// If not overridden, toolbar config will work without persistence (memory-only).
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return null; // Default: no persistence
});

/// Provider for toolbar configuration with persistence
final toolbarConfigProvider = StateNotifierProvider<ToolbarConfigNotifier, ToolbarConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ToolbarConfigNotifier(prefs);
});

/// Notifier for managing toolbar configuration
class ToolbarConfigNotifier extends StateNotifier<ToolbarConfig> {
  ToolbarConfigNotifier(this._prefs) : super(_loadConfig(_prefs));

  final SharedPreferences? _prefs;

  static ToolbarConfig _loadConfig(SharedPreferences? prefs) {
    if (prefs == null) {
      // No persistence available, use default
      return ToolbarConfig.defaultConfig();
    }
    
    final jsonString = prefs.getString(_toolbarConfigKey);
    if (jsonString != null) {
      try {
        return ToolbarConfig.fromJsonString(jsonString);
      } catch (e) {
        // Invalid JSON, return default
        return ToolbarConfig.defaultConfig();
      }
    }
    return ToolbarConfig.defaultConfig();
  }

  Future<void> _saveConfig() async {
    if (_prefs != null) {
      await _prefs!.setString(_toolbarConfigKey, state.toJsonString());
    }
    // If no prefs, just update state without persistence
  }

  /// Toggle visibility of a tool
  Future<void> toggleToolVisibility(ToolType toolType) async {
    state = state.toggleToolVisibility(toolType);
    await _saveConfig();
  }

  /// Reorder tools
  Future<void> reorderTools(int oldIndex, int newIndex) async {
    state = state.reorderTools(oldIndex, newIndex);
    await _saveConfig();
  }

  /// Toggle quick access bar visibility
  Future<void> toggleQuickAccess() async {
    state = state.copyWith(showQuickAccess: !state.showQuickAccess);
    await _saveConfig();
  }

  /// Update quick access colors
  Future<void> setQuickAccessColors(List<int> colors) async {
    state = state.copyWith(quickAccessColors: colors);
    await _saveConfig();
  }

  /// Update quick access thicknesses
  Future<void> setQuickAccessThicknesses(List<double> thicknesses) async {
    state = state.copyWith(quickAccessThicknesses: thicknesses);
    await _saveConfig();
  }

  /// Toggle visibility of an extra tool (ruler, audio, etc.)
  Future<void> toggleExtraTool(String key) async {
    final current = state.extraToolVisible(key);
    final updated = Map<String, bool>.from(state.extraToolVisibility);
    updated[key] = !current;
    state = state.copyWith(extraToolVisibility: updated);
    await _saveConfig();
  }

  /// Reset to default configuration
  Future<void> resetToDefault() async {
    state = ToolbarConfig.defaultConfig();
    await _saveConfig();
  }

  /// Update entire config (for bulk changes)
  Future<void> updateConfig(ToolbarConfig config) async {
    state = config;
    await _saveConfig();
  }
}

/// Provider for visible tools only (convenience)
final visibleToolsProvider = Provider<List<ToolConfig>>((ref) {
  return ref.watch(toolbarConfigProvider).visibleTools;
});

/// Provider for checking if a specific tool is visible
final isToolVisibleProvider = Provider.family<bool, ToolType>((ref, toolType) {
  final config = ref.watch(toolbarConfigProvider);
  return config.tools
      .firstWhere(
        (t) => t.toolType == toolType,
        orElse: () => ToolConfig(toolType: toolType),
      )
      .isVisible;
});
