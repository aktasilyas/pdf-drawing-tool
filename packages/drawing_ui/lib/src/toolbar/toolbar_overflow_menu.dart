import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_logic.dart';

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
    final palette = ChromePalette.of(context);
    final currentTool = ref.watch(currentToolProvider);

    // Check if any hidden tool is currently selected
    final hasSelectedHidden = hiddenTools.contains(currentTool);

    return PopupMenuButton<ToolType>(
      icon: PhosphorIcon(
        ElyanotesIcons.moreVert,
        size: ElyanotesIcons.actionSize,
        color: hasSelectedHidden
            ? theme.toolbarIconSelectedColor
            : theme.toolbarIconColor,
      ),
      tooltip: context.drawingStrings.toolbar.moreTools,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      position: PopupMenuPosition.under,
      color: palette.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      // PopupMenu takes a single elevation shadow, not a BoxShadow list:
      // use the panel token's colour as the closest match.
      elevation: ChromeSpacing.sm,
      shadowColor:
          DrawingShadows.panel(Theme.of(context).brightness).first.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChromeRadius.xl),
        side: BorderSide(color: palette.border),
      ),
      onSelected: (tool) {
        final wasSelected = isToolSelected(tool, currentTool);
        handleToolPressed(ref, tool);
        // Auto-open panel for newly selected tools since the user
        // explicitly chose them from the overflow menu.
        if (!wasSelected && toolsWithPanel.contains(tool)) {
          ref.read(activePanelProvider.notifier).state = tool;
        }
      },
      itemBuilder: (context) => hiddenTools.map((tool) {
        final isSelected = tool == currentTool;
        return PopupMenuItem<ToolType>(
          value: tool,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                ElyanotesIcons.iconForTool(tool, active: isSelected),
                size: ElyanotesIcons.actionSize,
                color: isSelected ? palette.accent : palette.textMuted,
              ),
              const SizedBox(width: ChromeSpacing.md),
              Text(
                tool.label(context.drawingStrings),
                style: TextStyle(
                  color: isSelected ? palette.accent : palette.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
