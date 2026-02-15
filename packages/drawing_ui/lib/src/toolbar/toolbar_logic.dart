import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';

/// Groups visible tools, collapsing pen and highlighter variants into a single
/// representative entry each.
///
/// Returns the ordered list of [ToolType] entries to display, where all pen
/// tools are represented by the currently active pen (or [ToolType.ballpointPen])
/// and all highlighter tools by the active highlighter (or [ToolType.highlighter]).
List<ToolType> getGroupedVisibleTools(
    ToolbarConfig config, ToolType currentTool) {
  final visibleTools = config.visibleTools.map((tc) => tc.toolType).toList();
  final result = <ToolType>[];
  bool penAdded = false, highlighterAdded = false;
  for (final tool in visibleTools) {
    if (penTools.contains(tool)) {
      if (!penAdded) {
        result.add(penTools.contains(currentTool)
            ? currentTool
            : ToolType.ballpointPen);
        penAdded = true;
      }
    } else if (highlighterTools.contains(tool)) {
      if (!highlighterAdded) {
        result.add(highlighterTools.contains(currentTool)
            ? currentTool
            : ToolType.highlighter);
        highlighterAdded = true;
      }
    } else {
      result.add(tool);
    }
  }
  return result;
}

/// Whether [tool] should appear selected given the [currentTool].
///
/// Pen group tools are all considered selected when any pen tool is current.
/// Same for highlighter group tools.
bool isToolSelected(ToolType tool, ToolType currentTool) {
  if (penTools.contains(tool) && penTools.contains(currentTool)) return true;
  if (highlighterTools.contains(tool) &&
      highlighterTools.contains(currentTool)) {
    return true;
  }
  return tool == currentTool;
}

/// Shared tool press handler for all toolbar variants.
///
/// Behaviour:
/// - **First click** (tool not selected): select the tool, close any panel.
/// - **Second click** (tool already selected): toggle the settings panel.
void handleToolPressed(WidgetRef ref, ToolType tool) {
  final currentTool = ref.read(currentToolProvider);
  final activePanel = ref.read(activePanelProvider);
  final alreadySelected = isToolSelected(tool, currentTool);

  if (alreadySelected) {
    // Already selected — toggle panel
    if (activePanel != null) {
      ref.read(activePanelProvider.notifier).state = null;
    } else {
      // Open panel for the *current* tool (not the group representative)
      ref.read(activePanelProvider.notifier).state = currentTool;
    }
  } else {
    // First click — just select, no panel
    ref.read(currentToolProvider.notifier).state = tool;
    ref.read(activePanelProvider.notifier).state = null;
  }
}
