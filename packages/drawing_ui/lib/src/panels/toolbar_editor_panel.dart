import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';

/// Panel for customizing toolbar layout.
class ToolbarEditorPanel extends ConsumerWidget {
  const ToolbarEditorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Customize Toolbar', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await ref.read(toolbarConfigProvider.notifier).resetToDefault();
              },
              child: Text('Reset', style: TextStyle(
                fontSize: 14, color: cs.primary, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 10),
          Text('Drag to reorder tools. Toggle visibility with the switch.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          const ReorderableToolList(),
        ],
      ),
    );
  }
}

