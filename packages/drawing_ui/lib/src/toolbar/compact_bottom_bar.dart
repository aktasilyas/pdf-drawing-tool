import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_logic.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';
import 'package:drawing_ui/src/toolbar/toolbar_overflow_menu.dart';

/// Compact bottom toolbar for phone screens (<600px).
///
/// Shows undo/redo + max 5 tool buttons + overflow menu.
/// Tool panels open as bottom sheets instead of anchored panels.
class CompactBottomBar extends ConsumerStatefulWidget {
  const CompactBottomBar({
    super.key,
    this.onUndoPressed,
    this.onRedoPressed,
    this.onPanelRequested,
  });

  final VoidCallback? onUndoPressed;
  final VoidCallback? onRedoPressed;

  /// Callback when a tool's panel should open as bottom sheet.
  /// DrawingScreen handles the actual showModalBottomSheet call.
  final ValueChanged<ToolType>? onPanelRequested;

  static const int maxVisibleTools = 5;

  @override
  ConsumerState<CompactBottomBar> createState() => _CompactBottomBarState();
}

class _CompactBottomBarState extends ConsumerState<CompactBottomBar> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final currentTool = ref.watch(currentToolProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);

    // Get grouped visible tools (same logic as MediumToolbar)
    final allTools = _getGroupedVisibleTools(toolbarConfig, currentTool);
    final shownTools = allTools.take(CompactBottomBar.maxVisibleTools).toList();
    final hiddenTools = allTools.skip(CompactBottomBar.maxVisibleTools).toList();

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const SizedBox(width: 8),

            // Undo/Redo
            ToolbarUndoRedoButtons(
              canUndo: canUndo,
              canRedo: canRedo,
              onUndo: widget.onUndoPressed,
              onRedo: widget.onRedoPressed,
            ),

            const SizedBox(width: 4),

            // Divider
            Container(
              width: 1,
              height: 28,
              color: colorScheme.outlineVariant,
            ),

            const SizedBox(width: 4),

            // Tool buttons (max 5)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: shownTools.map((tool) {
                  return _buildToolButton(tool, currentTool);
                }).toList(),
              ),
            ),

            // Overflow menu (if hidden tools exist)
            if (hiddenTools.isNotEmpty)
              ToolbarOverflowMenu(
                hiddenTools: hiddenTools,
              ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(ToolType tool, ToolType currentTool) {
    final isPenGroup = penTools.contains(tool);
    final isHighlighterGroup = highlighterTools.contains(tool);
    final isSelected = isToolSelected(tool, currentTool);
    final hasPanel = toolsWithPanel.contains(tool);

    return ToolButton(
      toolType: tool,
      isSelected: isSelected,
      onPressed: () => _onToolPressed(tool),
      onPanelTap: hasPanel ? () => _onPanelTap(tool) : null,
      hasPanel: hasPanel,
      customIcon: isPenGroup && penTools.contains(currentTool)
          ? ToolButton.getIconForTool(currentTool)
          : isHighlighterGroup && highlighterTools.contains(currentTool)
              ? ToolButton.getIconForTool(currentTool)
              : null,
    );
  }

  /// Get grouped visible tools (pen/highlighter groups collapsed).
  List<ToolType> _getGroupedVisibleTools(
      ToolbarConfig config, ToolType currentTool) {
    final visibleTools = config.visibleTools.map((tc) => tc.toolType).toList();
    final result = <ToolType>[];
    bool penAdded = false;
    bool highlighterAdded = false;

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

  /// Handle tool button press.
  void _onToolPressed(ToolType tool) {
    final currentTool = ref.read(currentToolProvider);
    if (isToolSelected(tool, currentTool)) {
      // Already selected — open panel (bottom sheet) if it has one
      if (toolsWithPanel.contains(currentTool)) {
        widget.onPanelRequested?.call(currentTool);
      }
    } else {
      // First click — just select
      ref.read(currentToolProvider.notifier).state = tool;
      ref.read(activePanelProvider.notifier).state = null;
      ref.read(penPickerModeProvider.notifier).state = false;
    }
  }

  /// Handle panel chevron tap.
  void _onPanelTap(ToolType tool) {
    ref.read(penPickerModeProvider.notifier).state = false;
    widget.onPanelRequested?.call(tool);
  }
}
