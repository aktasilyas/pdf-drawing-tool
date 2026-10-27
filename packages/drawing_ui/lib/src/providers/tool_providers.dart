import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/eraser_settings_provider.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// SharedPreferences key for persisting selected tool.
const _currentToolKey = 'elyanotes_current_tool';

/// Currently selected tool type with SharedPreferences persistence.
final currentToolProvider =
    StateNotifierProvider<CurrentToolNotifier, ToolType>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrentToolNotifier(
    prefs,
    // The last selected eraser type is remembered as the eraser mode.
    onEraserSelected: (mode) =>
        ref.read(eraserSettingsProvider.notifier).setMode(mode),
  );
});

/// Notifier for current tool selection with persistence.
class CurrentToolNotifier extends StateNotifier<ToolType> {
  CurrentToolNotifier(
    this._prefs, {
    ToolType? initialTool,
    void Function(EraserMode mode)? onEraserSelected,
  })  : _onEraserSelected = onEraserSelected,
        super(initialTool ?? _load(_prefs));

  final SharedPreferences? _prefs;
  final void Function(EraserMode mode)? _onEraserSelected;

  /// The tool saved in [prefs] (ballpoint pen when none).
  static ToolType loadSaved(SharedPreferences? prefs) => _load(prefs);

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

  /// Selects [tool] from any path (toolbar, panel, shortcuts); an eraser
  /// type is also remembered as the eraser mode.
  void selectTool(ToolType tool) {
    state = tool;
    _save();
    final mode = eraserModeForTool(tool);
    if (mode != null) _onEraserSelected?.call(mode);
  }
}

/// Tool that was active before switching to eraser (for autoLift).
final previousToolProvider = StateProvider<ToolType?>((ref) => null);

/// Whether a panel is currently open (and which one).
final activePanelProvider = StateProvider<ToolType?>((ref) {
  return null;
});
