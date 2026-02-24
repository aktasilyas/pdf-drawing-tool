import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_logic.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';
import 'package:drawing_ui/src/toolbar/toolbar_overflow_menu.dart';
import 'package:drawing_ui/src/toolbar/top_navigation_bar.dart';

/// Compact tool row for phone screens (<600px).
///
/// Sits as the second row in the top toolbar area.
/// Shows undo/redo + max 7 tool buttons + overflow menu.
/// Tool panels open as bottom sheets instead of anchored panels.
class CompactToolRow extends ConsumerStatefulWidget {
  const CompactToolRow({
    super.key,
    this.onAIPressed,
    this.onUndoPressed,
    this.onRedoPressed,
    this.onPanelRequested,
  });

  final VoidCallback? onAIPressed;
  final VoidCallback? onUndoPressed;
  final VoidCallback? onRedoPressed;

  /// Callback when a tool's panel should open as bottom sheet.
  final ValueChanged<ToolType>? onPanelRequested;

  static const int maxVisibleTools = 7;

  @override
  ConsumerState<CompactToolRow> createState() => _CompactToolRowState();
}

class _CompactToolRowState extends ConsumerState<CompactToolRow> {
  @override
  Widget build(BuildContext context) {
    final isReaderMode = ref.watch(readerModeProvider);
    if (isReaderMode) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final currentTool = ref.watch(currentToolProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);

    // Get grouped visible tools, excluding tools shown in the nav row.
    final topTools = TopNavigationBar.compactTopBarTools.toSet();
    final allTools = _getGroupedVisibleTools(toolbarConfig, currentTool)
        .where((t) => !topTools.contains(t))
        .toList();
    final shownTools =
        allTools.take(CompactToolRow.maxVisibleTools).toList();
    final hiddenTools =
        allTools.skip(CompactToolRow.maxVisibleTools).toList();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),

          // Undo/Redo
          ToolbarUndoRedoButtons(
            canUndo: canUndo,
            canRedo: canRedo,
            onUndo: widget.onUndoPressed,
            onRedo: widget.onRedoPressed,
          ),

          const SizedBox(width: 2),

          // Divider
          Container(
            width: 1,
            height: 28,
            color: colorScheme.outlineVariant,
          ),

          const SizedBox(width: 2),

          // Tool buttons
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

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildToolButton(ToolType tool, ToolType currentTool) {
    final isPenGroup = penTools.contains(tool);
    final isHighlighterGroup = highlighterTools.contains(tool);
    final isEraserGroup = eraserTools.contains(tool);
    final isSelected = isToolSelected(tool, currentTool);
    final hasPanel = toolsWithPanel.contains(tool);

    IconData? customIcon;
    if (isPenGroup && penTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    } else if (isHighlighterGroup && highlighterTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    } else if (isEraserGroup && eraserTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    }

    return ToolButton(
      toolType: tool,
      isSelected: isSelected,
      onPressed: () => _onToolPressed(tool),
      onPanelTap: hasPanel ? () => _onPanelTap(tool) : null,
      hasPanel: hasPanel,
      customIcon: customIcon,
      compact: true,
    );
  }

  /// Get grouped visible tools (pen/highlighter groups collapsed).
  List<ToolType> _getGroupedVisibleTools(
      ToolbarConfig config, ToolType currentTool) {
    final visibleTools = config.visibleTools.map((tc) => tc.toolType).toList();
    final result = <ToolType>[];
    bool penAdded = false;
    bool highlighterAdded = false;
    bool eraserAdded = false;

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
      } else if (eraserTools.contains(tool)) {
        if (!eraserAdded) {
          result.add(eraserTools.contains(currentTool)
              ? currentTool
              : ToolType.pixelEraser);
          eraserAdded = true;
        }
      } else {
        result.add(tool);
      }
    }
    return result;
  }

  /// Handle tool button press.
  void _onToolPressed(ToolType tool) {
    // Cancel sticker/image placement if active
    ref.read(stickerPlacementProvider.notifier).cancel();
    ref.read(imagePlacementProvider.notifier).cancel();

    final currentTool = ref.read(currentToolProvider);
    if (isToolSelected(tool, currentTool)) {
      // Already selected — open panel (bottom sheet) if it has one
      if (toolsWithPanel.contains(currentTool)) {
        widget.onPanelRequested?.call(currentTool);
      }
    } else {
      // First click — just select
      ref.read(currentToolProvider.notifier).selectTool(tool);
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
