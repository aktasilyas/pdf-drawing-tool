import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';

/// A reorderable list of tools for the settings panel.
class ReorderableToolList extends ConsumerWidget {
  const ReorderableToolList({super.key});

  /// Collapse grouped tools (pen, highlighter, eraser) into single entries.
  static List<ToolConfig> _collapseGroups(List<ToolConfig> sorted) {
    final result = <ToolConfig>[];
    bool penAdded = false, highlighterAdded = false, eraserAdded = false;
    for (final tool in sorted) {
      if (penTools.contains(tool.toolType)) {
        if (!penAdded) {
          result.add(tool);
          penAdded = true;
        }
      } else if (highlighterTools.contains(tool.toolType)) {
        if (!highlighterAdded) {
          result.add(tool);
          highlighterAdded = true;
        }
      } else if (eraserTools.contains(tool.toolType)) {
        if (!eraserAdded) {
          result.add(tool);
          eraserAdded = true;
        }
      } else {
        result.add(tool);
      }
    }
    return result;
  }

  static String _labelFor(ToolConfig tool) {
    if (penTools.contains(tool.toolType)) return 'Kalem';
    if (highlighterTools.contains(tool.toolType)) return 'Fosforlu Kalem';
    if (eraserTools.contains(tool.toolType)) return 'Silgi';
    return tool.toolType.displayName;
  }

  /// Returns all group members for a tool (or just itself if ungrouped).
  static List<ToolType> _groupOf(ToolType tool) {
    if (penTools.contains(tool)) return penTools;
    if (highlighterTools.contains(tool)) return highlighterTools;
    if (eraserTools.contains(tool)) return eraserTools;
    return [tool];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(toolbarConfigProvider);
    final displayTools = _collapseGroups(config.sortedTools);

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: displayTools.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex -= 1;
        // Reorder on the collapsed list, then assign new orders
        final reordered = List<ToolConfig>.of(displayTools);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);

        final newTools = List<ToolConfig>.from(config.tools);
        for (int i = 0; i < reordered.length; i++) {
          for (final member in _groupOf(reordered[i].toolType)) {
            final idx = newTools.indexWhere((t) => t.toolType == member);
            if (idx >= 0) {
              newTools[idx] = newTools[idx].copyWith(order: i);
            }
          }
        }
        await ref.read(toolbarConfigProvider.notifier)
            .updateConfig(config.copyWith(tools: newTools));
      },
      itemBuilder: (context, index) {
        final toolConfig = displayTools[index];
        return _CompactToolItem(
          key: ValueKey(toolConfig.toolType),
          index: index,
          icon: StarNoteIcons.iconForTool(toolConfig.toolType),
          label: _labelFor(toolConfig),
          isVisible: toolConfig.isVisible,
          onVisibilityToggle: () async {
            // Toggle all members of the group together
            final newVisible = !toolConfig.isVisible;
            var updated = ref.read(toolbarConfigProvider);
            for (final member in _groupOf(toolConfig.toolType)) {
              updated = updated.updateTool(
                member,
                (t) => t.copyWith(isVisible: newVisible),
              );
            }
            await ref.read(toolbarConfigProvider.notifier)
                .updateConfig(updated);
          },
        );
      },
    );
  }
}

/// A reorderable list of extra tools (ruler, audio, etc.).
class ReorderableExtraToolList extends ConsumerWidget {
  const ReorderableExtraToolList({super.key});

  static const _extraToolMeta = <String, ({IconData icon, String label})>{
    'ruler': (icon: StarNoteIcons.ruler, label: 'Cetvel'),
    'audio': (icon: StarNoteIcons.microphone, label: 'Ses Kaydı'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(toolbarConfigProvider);
    final sorted = config.sortedExtraTools;

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: sorted.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex -= 1;
        await ref.read(toolbarConfigProvider.notifier)
            .reorderExtraTools(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final extra = sorted[index];
        final meta = _extraToolMeta[extra.key];
        return _CompactToolItem(
          key: ValueKey(extra.key),
          index: index,
          icon: meta?.icon ?? StarNoteIcons.settings,
          label: meta?.label ?? extra.key,
          isVisible: extra.isVisible,
          onVisibilityToggle: () async {
            await ref.read(toolbarConfigProvider.notifier)
                .toggleExtraTool(extra.key);
          },
        );
      },
    );
  }
}

/// Compact reorderable tool row shared by both lists.
class _CompactToolItem extends StatelessWidget {
  const _CompactToolItem({
    super.key,
    required this.index,
    required this.icon,
    required this.label,
    required this.isVisible,
    required this.onVisibilityToggle,
  });

  final int index;
  final IconData icon;
  final String label;
  final bool isVisible;
  final VoidCallback onVisibilityToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
      decoration: BoxDecoration(
        color: isVisible
            ? cs.surface
            : (isDark
                ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
                : cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVisible
              ? cs.outline.withValues(alpha: 0.3)
              : cs.outline.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: PhosphorIcon(
                  StarNoteIcons.dragHandle,
                  color: cs.onSurfaceVariant,
                  size: 14,
                ),
              ),
            ),
            PhosphorIcon(
              icon,
              size: 14,
              color: isVisible
                  ? cs.onSurface
                  : cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.sourceSerif4(
                  fontSize: 11,
                  color: isVisible
                      ? cs.onSurface
                      : cs.onSurfaceVariant.withValues(alpha: 0.6),
                  decoration: isVisible ? null : TextDecoration.lineThrough,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Transform.scale(
              scale: 0.6,
              child: Switch(
                value: isVisible,
                onChanged: (_) => onVisibilityToggle(),
                activeThumbColor: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
