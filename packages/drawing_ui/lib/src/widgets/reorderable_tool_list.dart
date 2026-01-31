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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(
        color: isVisible 
            ? (isDark ? colorScheme.surface : colorScheme.surface) 
            : (isDark ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5) : colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVisible 
              ? colorScheme.outline.withValues(alpha: 0.3) 
              : colorScheme.outline.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Drag handle with larger touch area - ONLY THIS AREA IS DRAGGABLE
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? colorScheme.surfaceContainerHigh 
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.drag_indicator,
                      color: colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tool icon
                Icon(
                  _getToolIcon(toolConfig.toolType),
                  size: 16,
                  color: isVisible ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                // Tool name
                Expanded(
                  child: Text(
                    toolConfig.toolType.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: isVisible ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      decoration: isVisible ? null : TextDecoration.lineThrough,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Switch
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: isVisible,
                    onChanged: (_) => onVisibilityToggle(),
                    activeThumbColor: colorScheme.primary,
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
