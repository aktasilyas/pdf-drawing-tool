import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_logic.dart';
import 'package:drawing_ui/src/toolbar/toolbar_nav_sections.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';
import 'package:drawing_ui/src/toolbar/top_nav_menus.dart';

/// Expanded toolbar (>=840px) — single-row layout combining navigation and
/// drawing tools.
///
/// Layout (edit mode):
/// ```
/// [Nav Left] | [Tools...scroll...Settings] | [Nav Right]
/// ```
///
/// Layout (reader mode):
/// ```
/// [Nav Left]  ···spacer···  [Nav Right]
/// ```
class ToolBar extends ConsumerStatefulWidget {
  const ToolBar({
    super.key,
    this.onSettingsPressed,
    this.settingsButtonKey,
    this.toolButtonKeys,
    this.penGroupButtonKey,
    this.highlighterGroupButtonKey,
    this.documentTitle,
    this.onHomePressed,
    this.onTitlePressed,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
  });

  final VoidCallback? onSettingsPressed;
  final GlobalKey? settingsButtonKey;
  final Map<ToolType, GlobalKey>? toolButtonKeys;
  final GlobalKey? penGroupButtonKey;
  final GlobalKey? highlighterGroupButtonKey;

  // Nav parameters
  final String? documentTitle;
  final VoidCallback? onHomePressed;
  final VoidCallback? onTitlePressed;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;

  @override
  ConsumerState<ToolBar> createState() => _ToolBarState();
}

class _ToolBarState extends ConsumerState<ToolBar> {
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
    final gridVisible = ref.watch(gridVisibilityProvider);
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
            onTitlePressed: widget.onTitlePressed,
            onSidebarToggle: widget.onSidebarToggle,
            isSidebarOpen: widget.isSidebarOpen,
            isReaderMode: isReaderMode,
            pageCount: pageCount,
          ),
          // Tools section (hidden in reader mode)
          if (!isReaderMode) ..._buildToolsSection(theme),
          // Spacer pushes nav right to the end in reader mode
          if (isReaderMode) const Expanded(child: SizedBox()),
          // Nav right section
          ToolbarNavRight(
            isReaderMode: isReaderMode,
            gridVisible: gridVisible,
            onReaderToggle: () =>
                ref.read(readerModeProvider.notifier).state = !isReaderMode,
            onGridToggle: () =>
                ref.read(gridVisibilityProvider.notifier).state = !gridVisible,
            onExportPressed: () => showExportMenu(context, ref),
            onMorePressed: () => showMoreMenu(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Build scrollable tools + settings button.
  List<Widget> _buildToolsSection(DrawingTheme theme) {
    final currentTool = ref.watch(currentToolProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);
    final visibleTools = getGroupedVisibleTools(toolbarConfig, currentTool);

    return [
      const ToolbarVerticalDivider(),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...visibleTools.map((tool) => _buildToolButton(tool, currentTool)),
              _buildSettingsButton(theme),
            ],
          ),
        ),
      ),
      const ToolbarVerticalDivider(),
    ];
  }

  Widget _buildToolButton(ToolType tool, ToolType currentTool) {
    final isPenGroup = penTools.contains(tool);
    final isHighlighterGroup = highlighterTools.contains(tool);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ToolButton(
        key: buttonKey,
        toolType: tool,
        isSelected: selected,
        buttonKey: _toolButtonKeys[tool],
        onPressed: () => _onToolPressed(tool),
        onPanelTap: hasPanel ? () => _onPanelTap(tool) : null,
        hasPanel: hasPanel,
        customIcon: isPenGroup && penTools.contains(currentTool)
            ? ToolButton.getIconForTool(currentTool)
            : null,
      ),
    );
  }

  Widget _buildSettingsButton(DrawingTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: 'Araç Çubuğu Ayarları',
        child: Semantics(
          label: 'Araç Çubuğu Ayarları',
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final current = ref.read(activePanelProvider);
              ref.read(activePanelProvider.notifier).state =
                  current == ToolType.toolbarSettings
                      ? null
                      : ToolType.toolbarSettings;
            },
            child: Container(
              key: widget.settingsButtonKey,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.toolbarBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: PhosphorIcon(
                StarNoteIcons.settings,
                size: StarNoteIcons.actionSize,
                color: theme.toolbarIconColor,
                semanticLabel: 'Araç Çubuğu Ayarları',
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onToolPressed(ToolType tool) {
    if (penToolsSet.contains(tool)) {
      final currentTool = ref.read(currentToolProvider);
      final activePanel = ref.read(activePanelProvider);
      if (penToolsSet.contains(currentTool) &&
          penToolsSet.contains(activePanel)) {
        ref.read(activePanelProvider.notifier).state = null;
        return;
      }
      if (currentTool != tool) {
        ref.read(currentToolProvider.notifier).state = tool;
      }
      ref.read(activePanelProvider.notifier).state = tool;
      return;
    }
    ref.read(currentToolProvider.notifier).state = tool;
    ref.read(activePanelProvider.notifier).state = null;
  }

  void _onPanelTap(ToolType tool) {
    final active = ref.read(activePanelProvider);
    ref.read(activePanelProvider.notifier).state =
        active == tool ? null : tool;
  }

  GlobalKey? getToolButtonKey(ToolType tool) => _toolButtonKeys[tool];
}
