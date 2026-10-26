import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// SharedPreferences key for persisting selected tool.
const _currentToolKey = 'elyanotes_current_tool';

/// Currently selected tool type with SharedPreferences persistence.
final currentToolProvider =
    StateNotifierProvider<CurrentToolNotifier, ToolType>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrentToolNotifier(prefs);
});

/// Notifier for current tool selection with persistence.
class CurrentToolNotifier extends StateNotifier<ToolType> {
  CurrentToolNotifier(this._prefs, {ToolType? initialTool})
      : super(initialTool ?? _load(_prefs));

  final SharedPreferences? _prefs;

  static ToolType _load(SharedPreferences? prefs) {
    if (prefs == null) return ToolType.ballpointPen;
    final name = prefs.getString(_currentToolKey);
    if (name != null) {
      try {
        return ToolType.values.firstWhere((t) => t.name == name);
      } catch (_) {}
    }
    return ToolType.ballpointPen;
  }

  Future<void> _save() async {
    await _prefs?.setString(_currentToolKey, state.name);
  }

  void selectTool(ToolType tool) {
    state = tool;
    _save();
  }
}

/// Tool that was active before switching to eraser (for autoLift).
final previousToolProvider = StateProvider<ToolType?>((ref) => null);

/// Whether a panel is currently open (and which one).
final activePanelProvider = StateProvider<ToolType?>((ref) {
  return null;
});

