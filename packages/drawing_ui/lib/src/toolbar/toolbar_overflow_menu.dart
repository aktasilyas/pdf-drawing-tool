import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Overflow menu for tools that don't fit in the medium toolbar.
///
/// Shows hidden tools as a [PopupMenuButton] with icon + display name.
/// Tapping an item selects the tool and closes any open panel.
class ToolbarOverflowMenu extends ConsumerWidget {
  const ToolbarOverflowMenu({
    super.key,
    required this.hiddenTools,
  });

  /// Tools that are hidden from the main toolbar row.
  final List<ToolType> hiddenTools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = DrawingTheme.of(context);
    final currentTool = ref.watch(currentToolProvider);

    // Check if any hidden tool is currently selected
    final hasSelectedHidden = hiddenTools.contains(currentTool);

    return PopupMenuButton<ToolType>(
      icon: PhosphorIcon(
        StarNoteIcons.moreVert,
        size: StarNoteIcons.actionSize,
        color: hasSelectedHidden
            ? theme.toolbarIconSelectedColor
            : theme.toolbarIconColor,
      ),
      tooltip: 'Daha fazla arac',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      position: PopupMenuPosition.under,
      onSelected: (tool) {
        ref.read(currentToolProvider.notifier).state = tool;
        ref.read(activePanelProvider.notifier).state = null;
      },
      itemBuilder: (context) => hiddenTools.map((tool) {
        final isSelected = tool == currentTool;
        return PopupMenuItem<ToolType>(
          value: tool,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                StarNoteIcons.iconForTool(tool, active: isSelected),
                size: StarNoteIcons.actionSize,
                color: isSelected
                    ? theme.toolbarIconSelectedColor
                    : theme.toolbarIconColor,
              ),
              const SizedBox(width: 12),
              Text(
                tool.displayName,
                style: TextStyle(
                  color: isSelected
                      ? theme.toolbarIconSelectedColor
                      : null,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
