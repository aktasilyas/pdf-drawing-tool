import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// A reorderable list of tools for the settings panel.
class ReorderableToolList extends ConsumerWidget {
  const ReorderableToolList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(toolbarConfigProvider);
    final sortedTools = config.sortedTools;

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: sortedTools.length,
      onReorder: (oldIndex, newIndex) async {
        // Adjust for ReorderableListView behavior
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        await ref.read(toolbarConfigProvider.notifier).reorderTools(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final toolConfig = sortedTools[index];
        return _ToolListItem(
          key: ValueKey(toolConfig.toolType),
          index: index,
          toolConfig: toolConfig,
          onVisibilityToggle: () async {
            await ref.read(toolbarConfigProvider.notifier)
                .toggleToolVisibility(toolConfig.toolType);
          },
        );
      },
    );
  }
}

class _ToolListItem extends StatelessWidget {
  const _ToolListItem({
    super.key,
    required this.index,
    required this.toolConfig,
    required this.onVisibilityToggle,
  });

  final int index;
  final ToolConfig toolConfig;
  final VoidCallback onVisibilityToggle;

  @override
  Widget build(BuildContext context) {
    final isVisible = toolConfig.isVisible;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(
        color: isVisible ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVisible ? Colors.grey.shade300 : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Drag handle with larger touch area - ONLY THIS AREA IS DRAGGABLE
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.drag_indicator,
                      color: Colors.grey.shade700,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tool icon
                Icon(
                  _getToolIcon(toolConfig.toolType),
                  size: 18,
                  color: isVisible ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
                const SizedBox(width: 10),
                // Tool name
                Expanded(
                  child: Text(
                    toolConfig.toolType.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isVisible ? Colors.grey.shade800 : Colors.grey.shade500,
                      decoration: isVisible ? null : TextDecoration.lineThrough,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Switch
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: isVisible,
                    onChanged: (_) => onVisibilityToggle(),
                    activeColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getToolIcon(ToolType type) {
    switch (type) {
      case ToolType.ballpointPen:
      case ToolType.gelPen:
      case ToolType.dashedPen:
        return Icons.edit;
      case ToolType.pencil:
      case ToolType.hardPencil:
        return Icons.edit_outlined;
      case ToolType.highlighter:
      case ToolType.neonHighlighter:
        return Icons.highlight;
      case ToolType.brushPen:
        return Icons.brush;
      case ToolType.rulerPen:
        return Icons.straighten;
      case ToolType.pixelEraser:
      case ToolType.strokeEraser:
      case ToolType.lassoEraser:
        return Icons.auto_fix_normal;
      case ToolType.selection:
        return Icons.touch_app;
      case ToolType.shapes:
        return Icons.category;
      case ToolType.text:
        return Icons.text_fields;
      case ToolType.sticker:
        return Icons.emoji_emotions;
      case ToolType.image:
        return Icons.image;
      case ToolType.panZoom:
        return Icons.pan_tool;
      case ToolType.laserPointer:
        return Icons.location_searching;
      case ToolType.toolbarSettings:
        return Icons.tune;
    }
  }
}
