import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

/// Key for storing toolbar config in SharedPreferences
const _toolbarConfigKey = 'starnote_toolbar_config';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

/// Provider for toolbar configuration with persistence
final toolbarConfigProvider = StateNotifierProvider<ToolbarConfigNotifier, ToolbarConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ToolbarConfigNotifier(prefs);
});

/// Notifier for managing toolbar configuration
class ToolbarConfigNotifier extends StateNotifier<ToolbarConfig> {
  ToolbarConfigNotifier(this._prefs) : super(_loadConfig(_prefs));

  final SharedPreferences _prefs;

  static ToolbarConfig _loadConfig(SharedPreferences prefs) {
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
    await _prefs.setString(_toolbarConfigKey, state.toJsonString());
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
