import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Panel for customizing toolbar layout.
///
/// Allows reordering tools and toggling visibility.
/// All changes update MOCK state only.
class ToolbarEditorPanel extends ConsumerWidget {
  const ToolbarEditorPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(toolbarConfigProvider);

    return ToolPanel(
      title: 'Customize Toolbar',
      onClose: onClose,
      headerActions: [
        GestureDetector(
          onTap: () {
            ref.read(toolbarConfigProvider.notifier).resetToDefault();
          },
          child: const Text(
            'Reset',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drag to reorder tools. Toggle visibility with the switch.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          // Reorderable tool list
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: config.toolOrder.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              ref
                  .read(toolbarConfigProvider.notifier)
                  .reorderTools(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final tool = config.toolOrder[index];
              final isVisible = config.visibleTools.contains(tool);
              return _ToolListItem(
                key: ValueKey(tool),
                tool: tool,
                isVisible: isVisible,
                onVisibilityChanged: (visible) {
                  ref
                      .read(toolbarConfigProvider.notifier)
                      .setToolVisibility(tool, visible);
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Done button
          PanelActionButton(
            label: 'Done',
            isPrimary: true,
            onPressed: () => onClose?.call(),
          ),
        ],
      ),
    );
  }
}

/// A single tool item in the reorderable list.
class _ToolListItem extends StatelessWidget {
  const _ToolListItem({
    super.key,
    required this.tool,
    required this.isVisible,
    required this.onVisibilityChanged,
  });

  final ToolType tool;
  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: 0, // This will be overridden by ReorderableListView
          child: const Icon(Icons.drag_handle, color: Colors.grey),
        ),
        title: Row(
          children: [
            Icon(
              _getIconForTool(tool),
              size: 20,
              color: isVisible ? Colors.black87 : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              tool.displayName,
              style: TextStyle(
                fontSize: 14,
                color: isVisible ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Switch(
          value: isVisible,
          onChanged: onVisibilityChanged,
          activeColor: Colors.blue,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  IconData _getIconForTool(ToolType type) {
    switch (type) {
      case ToolType.pencil:
        return Icons.edit_outlined;
      case ToolType.hardPencil:
        return Icons.create;
      case ToolType.ballpointPen:
        return Icons.edit;
      case ToolType.gelPen:
        return Icons.edit;
      case ToolType.dashedPen:
        return Icons.timeline;
      case ToolType.brushPen:
        return Icons.brush;
      case ToolType.marker:
        return Icons.border_color;
      case ToolType.neonHighlighter:
        return Icons.flash_on;
      case ToolType.highlighter:
        return Icons.highlight;
      case ToolType.calligraphyPen:
        return Icons.gesture;
      case ToolType.pixelEraser:
        return Icons.auto_fix_normal;
      case ToolType.strokeEraser:
        return Icons.cleaning_services;
      case ToolType.lassoEraser:
        return Icons.gesture;
      case ToolType.shapes:
        return Icons.crop_square;
      case ToolType.text:
        return Icons.text_fields;
      case ToolType.sticker:
        return Icons.emoji_emotions;
      case ToolType.image:
        return Icons.image;
      case ToolType.selection:
        return Icons.select_all;
      case ToolType.panZoom:
        return Icons.pan_tool;
      case ToolType.laserPointer:
        return Icons.highlight_alt;
    }
  }
}
