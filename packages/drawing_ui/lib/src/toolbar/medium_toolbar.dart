import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_logic.dart';
import 'package:drawing_ui/src/toolbar/starnote_nav_button.dart';
import 'package:drawing_ui/src/toolbar/toolbar_nav_sections.dart';
import 'package:drawing_ui/src/toolbar/toolbar_overflow_menu.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';

/// Medium toolbar layout for 600-839px screens (tablet portrait).
///
/// Single-row layout combining navigation and drawing tools:
/// ```
/// [Nav Left] | [tools (dynamic)] [AI] [overflow] | [Nav Right]
/// ```
///
/// Reader mode: hides tool section, shows only nav.
class MediumToolbar extends ConsumerStatefulWidget {
  const MediumToolbar({
    super.key,
    this.onAIPressed,
    this.onSettingsPressed,
    this.settingsButtonKey,
    this.toolButtonKeys,
    this.penGroupButtonKey,
    this.highlighterGroupButtonKey,
    this.documentTitle,
    this.onHomePressed,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
  });

  final VoidCallback? onAIPressed;
  final VoidCallback? onSettingsPressed;
  final GlobalKey? settingsButtonKey;
  final Map<ToolType, GlobalKey>? toolButtonKeys;
  final GlobalKey? penGroupButtonKey;
  final GlobalKey? highlighterGroupButtonKey;

  // Nav parameters
  final String? documentTitle;
  final VoidCallback? onHomePressed;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;

  @override
  ConsumerState<MediumToolbar> createState() => _MediumToolbarState();
}

class _MediumToolbarState extends ConsumerState<MediumToolbar> {
  final Map<ToolType, GlobalKey> _toolButtonKeys = {};

  @override
  void initState() {
    super.initState();
    for (final tool in ToolType.values) {
      _toolButtonKeys[tool] = GlobalKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final isReaderMode = ref.watch(readerModeProvider);
    final pageCount = ref.watch(pageCountProvider);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.toolbarBackground,
        border: Border(
          bottom: BorderSide(
            color: theme.panelBorderColor.withValues(alpha: 80.0 / 255.0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          // Nav left section
          ToolbarNavLeft(
            documentTitle: widget.documentTitle,
            onHomePressed: widget.onHomePressed,
            onRenameDocument: widget.onRenameDocument,
            onDeleteDocument: widget.onDeleteDocument,
            onSidebarToggle: widget.onSidebarToggle,
            isSidebarOpen: widget.isSidebarOpen,
            isReaderMode: isReaderMode,
            pageCount: pageCount,
            showTitle: false,
          ),
          // Tools section (hidden in reader mode)
          if (!isReaderMode)
            Expanded(child: _buildDynamicToolsSection(theme))
          else
            const Spacer(),
          // Nav right section
          ToolbarNavRight(
            isReaderMode: isReaderMode,
            onReaderToggle: () =>
                ref.read(readerModeProvider.notifier).state = !isReaderMode,
            onShowRecordings: () => _openRecordingsTab(ref),
            documentTitle: widget.documentTitle,
            onRenameDocument: widget.onRenameDocument,
            onDeleteDocument: widget.onDeleteDocument,
            showAddPage: false,
            showExport: false,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Build tools section with dynamic tool count based on available width.
  Widget _buildDynamicToolsSection(DrawingTheme theme) {
    final currentTool = ref.watch(currentToolProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);
    final allTools = getGroupedVisibleTools(toolbarConfig, currentTool);
    final hasAI = widget.onAIPressed != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const toolSlotWidth = 42.0;
        const overflowWidth = 48.0;
        const dividerWidth = 17.0;
        const aiButtonWidth = 40.0;

        // Subtract fixed elements: divider + optional AI button + divider
        var available = constraints.maxWidth - dividerWidth;
        if (hasAI) available -= aiButtonWidth + dividerWidth;

        final totalTools = allTools.length;
        var max =
            (available / toolSlotWidth).floor().clamp(0, totalTools);
        var shownTools = allTools.take(max).toList();
        var hiddenTools = allTools.skip(max).toList();

        if (hiddenTools.isNotEmpty && max > 0) {
          max = ((available - overflowWidth) / toolSlotWidth)
              .floor()
              .clamp(1, totalTools);
          shownTools = allTools.take(max).toList();
          hiddenTools = allTools.skip(max).toList();
        }

        return Row(
          children: [
            const ToolbarVerticalDivider(),
            if (hasAI)
              StarNoteNavButton(
                icon: StarNoteIcons.sparkle,
                tooltip: 'Yapay Zeka',
                onPressed: widget.onAIPressed!,
              ),
            if (hasAI) const ToolbarVerticalDivider(),
            ...shownTools
                .map((tool) => _buildToolButton(tool, currentTool)),
            if (hiddenTools.isNotEmpty)
              ToolbarOverflowMenu(hiddenTools: hiddenTools),
            const Spacer(),
          ],
        );
      },
    );
  }

  Widget _buildToolButton(ToolType tool, ToolType currentTool) {
    final isPenGroup = penTools.contains(tool);
    final isHighlighterGroup = highlighterTools.contains(tool);
    final isEraserGroup = eraserTools.contains(tool);
    final selected = isToolSelected(tool, currentTool);
    final hasPanel = toolsWithPanel.contains(tool);

    final GlobalKey? buttonKey;
    if (isPenGroup) {
      buttonKey = widget.penGroupButtonKey;
    } else if (isHighlighterGroup) {
      buttonKey = widget.highlighterGroupButtonKey;
    } else {
      buttonKey = widget.toolButtonKeys?[tool];
    }

    IconData? customIcon;
    if (isPenGroup && penTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    } else if (isEraserGroup && eraserTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: ToolButton(
        key: buttonKey,
        toolType: tool,
        isSelected: selected,
        buttonKey: _toolButtonKeys[tool],
        onPressed: () => _onToolPressed(tool),
        onPanelTap: hasPanel ? () => _onPanelTap(tool) : null,
        hasPanel: hasPanel,
        customIcon: customIcon,
      ),
    );
  }

  void _onToolPressed(ToolType tool) => handleToolPressed(ref, tool);

  void _onPanelTap(ToolType tool) {
    final active = ref.read(activePanelProvider);
    ref.read(activePanelProvider.notifier).state =
        active == tool ? null : tool;
  }

  void _openRecordingsTab(WidgetRef ref) {
    ref.read(sidebarFilterProvider.notifier).state = SidebarFilter.recordings;
    if (!widget.isSidebarOpen) widget.onSidebarToggle?.call();
  }
}
