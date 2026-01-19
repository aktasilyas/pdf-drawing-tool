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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
    required this.toolConfig,
    required this.onVisibilityToggle,
  });

  final ToolConfig toolConfig;
  final VoidCallback onVisibilityToggle;

  @override
  Widget build(BuildContext context) {
    final isVisible = toolConfig.isVisible;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isVisible ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVisible ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.drag_handle,
          color: Colors.grey.shade400,
        ),
        title: Row(
          children: [
            Icon(
              _getToolIcon(toolConfig.toolType),
              size: 20,
              color: isVisible ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                toolConfig.toolType.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: isVisible ? Colors.grey.shade800 : Colors.grey.shade500,
                  decoration: isVisible ? null : TextDecoration.lineThrough,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Switch(
          value: isVisible,
          onChanged: (_) => onVisibilityToggle(),
          activeColor: Colors.blue,
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
