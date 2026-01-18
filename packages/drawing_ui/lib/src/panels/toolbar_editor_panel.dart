import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';

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
    return ToolPanel(
      title: 'Customize Toolbar',
      onClose: onClose,
      headerActions: [
        GestureDetector(
          onTap: () async {
            await ref.read(toolbarConfigProvider.notifier).resetToDefault();
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
          const ReorderableToolList(),
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

