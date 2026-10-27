import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/pen_box_presets_provider.dart';
import 'package:drawing_ui/src/providers/pen_settings_provider.dart';
import 'package:drawing_ui/src/providers/tool_providers.dart';

/// The settings panel that edits a preset of [toolType].
///
/// Both highlighter kinds share the highlighter panel; every other tool opens
/// its own panel.
ToolType penBoxEditorPanelFor(ToolType toolType) {
  if (toolType == ToolType.highlighter ||
      toolType == ToolType.neonHighlighter) {
    return ToolType.highlighter;
  }
  return toolType;
}

/// Whether the floating pen box at [position] lays its pens out in a row.
///
/// The box opens horizontally only near the top of the screen and away from
/// both side edges; otherwise it opens as a column.
bool penBoxOpensHorizontally({
  required Offset position,
  required double screenWidth,
}) {
  final isNearLeftEdge = position.dx < 80;
  final isNearRightEdge = position.dx > screenWidth - 150;
  final isNearTop = position.dy < 200;
  return !isNearLeftEdge && !isNearRightEdge && isNearTop;
}

/// What the floating pen box does when a preset is tapped, double-tapped or
/// deleted. Kept out of the widget so it can be tested without a canvas.
class PenBoxActions {
  /// Creates the actions bound to [_ref].
  PenBoxActions(this._ref);

  final Ref _ref;

  /// Activates the preset at [index] (an index into [penBoxPresetsProvider]):
  /// marks it selected, switches to its tool, applies its colour, thickness
  /// and nib, and closes any open panel. Out-of-range or empty slots do
  /// nothing.
  void selectPreset(int index) {
    final presets = _ref.read(penBoxPresetsProvider);
    if (index < 0 || index >= presets.length) return;
    final preset = presets[index];
    if (preset.isEmpty) return;

    _ref.read(selectedPresetIndexProvider.notifier).state = index;
    _ref.read(currentToolProvider.notifier).selectTool(preset.toolType);
    _ref.read(penSettingsProvider(preset.toolType).notifier)
      ..setColor(preset.color)
      ..setThickness(preset.thickness)
      ..setNibShape(preset.nibShape);
    _ref.read(activePanelProvider.notifier).state = null;
  }

  /// Opens the settings panel that edits [preset].
  void openEditor(PenPreset preset) {
    _ref.read(activePanelProvider.notifier).state =
        penBoxEditorPanelFor(preset.toolType);
  }

  /// Removes the preset at [index] from the box.
  void deletePreset(int index) {
    _ref.read(penBoxPresetsProvider.notifier).removePreset(index);
  }
}

/// Provides [PenBoxActions].
final penBoxActionsProvider = Provider<PenBoxActions>(PenBoxActions.new);
