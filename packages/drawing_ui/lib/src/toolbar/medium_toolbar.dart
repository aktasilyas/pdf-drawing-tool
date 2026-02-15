import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/quick_access_row.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_overflow_menu.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';

/// Medium toolbar layout for 600-839px screens (tablet portrait).
///
/// Shows: undo/redo | first 6 tools | settings | overflow menu
/// Below: collapsible quick access row (toggle with chevron).
/// Reuses [ToolButton], [ToolbarUndoRedoButtons], [QuickAccessRow].
class MediumToolbar extends ConsumerStatefulWidget {
  const MediumToolbar({
    super.key,
    this.onUndoPressed,
    this.onRedoPressed,
    this.onSettingsPressed,
    this.settingsButtonKey,
    this.toolButtonKeys,
    this.penGroupButtonKey,
    this.highlighterGroupButtonKey,
  });

  final VoidCallback? onUndoPressed;
  final VoidCallback? onRedoPressed;
  final VoidCallback? onSettingsPressed;
  final GlobalKey? settingsButtonKey;
  final Map<ToolType, GlobalKey>? toolButtonKeys;
  final GlobalKey? penGroupButtonKey;
  final GlobalKey? highlighterGroupButtonKey;

  @override
  ConsumerState<MediumToolbar> createState() => _MediumToolbarState();
}

class _MediumToolbarState extends ConsumerState<MediumToolbar> {
  static const _maxVisibleTools = 6;

  final Map<ToolType, GlobalKey> _toolButtonKeys = {};
  bool _showQuickAccess = false;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMainRow(theme),
        if (_showQuickAccess) _buildQuickAccessRow(theme),
      ],
    );
  }

  Widget _buildMainRow(DrawingTheme theme) {
    final currentTool = ref.watch(currentToolProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);

    final allTools = _getGroupedVisibleTools(toolbarConfig, currentTool);
    final visibleTools = allTools.take(_maxVisibleTools).toList();
    final hiddenTools = allTools.skip(_maxVisibleTools).toList();
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

          // Undo/Redo
          ToolbarUndoRedoButtons(
            canUndo: canUndo,
            canRedo: canRedo,
            onUndo: widget.onUndoPressed,
            onRedo: widget.onRedoPressed,
          ),

          const ToolbarVerticalDivider(),

          // Visible tools (first 6)
          ...visibleTools.map((tool) => _buildToolButton(tool, currentTool)),

          // Settings button
          _buildSettingsButton(theme),

          // Overflow menu (if hidden tools exist)
          if (hiddenTools.isNotEmpty)
            ToolbarOverflowMenu(hiddenTools: hiddenTools),

          const Spacer(),

          // Quick access toggle
          _buildQuickAccessToggle(theme),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildToolButton(ToolType tool, ToolType currentTool) {
    final isPenGroup = penTools.contains(tool);
    final isHighlighterGroup = highlighterTools.contains(tool);
    final isSelected = _isToolSelected(tool, currentTool);
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
        isSelected: isSelected,
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
    return Tooltip(
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
            width: 48, height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 2),
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
    );
  }

  Widget _buildQuickAccessToggle(DrawingTheme theme) {
    final label =
        _showQuickAccess ? 'Hızlı Erişimi Gizle' : 'Hızlı Erişimi Göster';
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          onTap: () => setState(() => _showQuickAccess = !_showQuickAccess),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _showQuickAccess
                  ? theme.toolbarIconSelectedColor.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: PhosphorIcon(
              _showQuickAccess
                  ? StarNoteIcons.caretUp
                  : StarNoteIcons.caretDown,
              size: StarNoteIcons.actionSize,
              color: theme.toolbarIconColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessRow(DrawingTheme theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.toolbarBackground,
        border: Border(
          bottom: BorderSide(
            color: theme.panelBorderColor.withValues(alpha: 80.0 / 255.0),
            width: 0.5,
          ),
        ),
      ),
      child: const Center(child: QuickAccessRow()),
    );
  }

  List<ToolType> _getGroupedVisibleTools(
      ToolbarConfig config, ToolType currentTool) {
    final visibleTools =
        config.visibleTools.map((tc) => tc.toolType).toList();
    final result = <ToolType>[];
    bool penAdded = false, highlighterAdded = false;
    for (final tool in visibleTools) {
      if (penTools.contains(tool)) {
        if (!penAdded) {
          result.add(penTools.contains(currentTool)
              ? currentTool : ToolType.ballpointPen);
          penAdded = true;
        }
      } else if (highlighterTools.contains(tool)) {
        if (!highlighterAdded) {
          result.add(highlighterTools.contains(currentTool)
              ? currentTool : ToolType.highlighter);
          highlighterAdded = true;
        }
      } else {
        result.add(tool);
      }
    }
    return result;
  }

  bool _isToolSelected(ToolType tool, ToolType currentTool) {
    if (penTools.contains(tool) && penTools.contains(currentTool)) return true;
    if (highlighterTools.contains(tool) &&
        highlighterTools.contains(currentTool)) return true;
    return tool == currentTool;
  }

  void _onToolPressed(ToolType tool) {
    // Pen group tap → direkt ayar paneli aç
    if (penToolsSet.contains(tool)) {
      final currentTool = ref.read(currentToolProvider);
      final activePanel = ref.read(activePanelProvider);
      // Panel zaten açıksa kapat
      if (penToolsSet.contains(currentTool) &&
          penToolsSet.contains(activePanel)) {
        ref.read(activePanelProvider.notifier).state = null;
        return;
      }
      if (currentTool != tool) {
        ref.read(currentToolProvider.notifier).state = tool;
      }
      // Direkt ayar paneli aç (picker yok)
      ref.read(activePanelProvider.notifier).state = tool;
      return;
    }

    ref.read(currentToolProvider.notifier).state = tool;
    ref.read(activePanelProvider.notifier).state = null;
  }

  void _onPanelTap(ToolType tool) {
    final active = ref.read(activePanelProvider);
    if (active == tool) {
      ref.read(activePanelProvider.notifier).state = null;
    } else {
      ref.read(activePanelProvider.notifier).state = tool;
    }
  }
}
