import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/quick_access_row.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';

/// Tool bar (Row 2) - Drawing tools and quick access.
///
/// Contains:
/// - Undo/Redo buttons (leftmost)
/// - Tool selection (scrollable)
/// - Quick color chips
/// - Quick thickness dots
/// - Toolbar config button
class ToolBar extends ConsumerStatefulWidget {
  const ToolBar({
    super.key,
    this.onUndoPressed,
    this.onRedoPressed,
    this.onSettingsPressed,
    this.settingsButtonKey,
    this.toolButtonKeys,
    this.penGroupButtonKey,
    this.highlighterGroupButtonKey,
  });

  /// Callback when undo is pressed.
  final VoidCallback? onUndoPressed;

  /// Callback when redo is pressed.
  final VoidCallback? onRedoPressed;

  /// Callback when toolbar config is pressed.
  final VoidCallback? onSettingsPressed;

  /// GlobalKey for settings button (for anchored panel positioning)
  final GlobalKey? settingsButtonKey;

  /// GlobalKeys for each tool button (for anchored panel positioning)
  final Map<ToolType, GlobalKey>? toolButtonKeys;

  /// Single GlobalKey for pen group button (all pen tools share this)
  final GlobalKey? penGroupButtonKey;

  /// Single GlobalKey for highlighter group button
  final GlobalKey? highlighterGroupButtonKey;

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
    final currentTool = ref.watch(currentToolProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);

    // Görünür araçları al ve kalem araçlarını grupla
    final visibleTools = _getGroupedVisibleTools(toolbarConfig, currentTool);

    return _buildExpandedLayout(
      context: context,
      theme: theme,
      canUndo: canUndo,
      canRedo: canRedo,
      currentTool: currentTool,
      visibleTools: visibleTools,
    );
  }

  Widget _buildExpandedLayout({
    required BuildContext context,
    required DrawingTheme theme,
    required bool canUndo,
    required bool canRedo,
    required ToolType currentTool,
    required List<ToolType> visibleTools,
  }) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Küçük ekranlarda QuickAccessRow'u gizle
          final showQuickAccess = constraints.maxWidth > 500;

          return Row(
            children: [
              const SizedBox(width: 4),

              // Undo/Redo section
              ToolbarUndoRedoButtons(
                canUndo: canUndo,
                canRedo: canRedo,
                onUndo: widget.onUndoPressed,
                onRedo: widget.onRedoPressed,
              ),

              // Divider
              const ToolbarVerticalDivider(),

              // Tools section (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...visibleTools.map((tool) {
                        final isPenGroup = penTools.contains(tool);
                        final isHighlighterGroup =
                            highlighterTools.contains(tool);
                        final isSelected =
                            _isToolSelected(tool, currentTool);
                        final hasPanel = toolsWithPanel.contains(tool);

                        final GlobalKey? buttonKey;
                        if (isPenGroup) {
                          buttonKey = widget.penGroupButtonKey;
                        } else if (isHighlighterGroup) {
                          buttonKey = widget.highlighterGroupButtonKey;
                        } else {
                          buttonKey = widget.toolButtonKeys?[tool];
                        }

                        Widget toolButton = ToolButton(
                          key: buttonKey,
                          toolType: tool,
                          isSelected: isSelected,
                          buttonKey: _toolButtonKeys[tool],
                          onPressed: () => _onToolPressed(tool),
                          onPanelTap:
                              hasPanel ? () => _onPanelTap(tool) : null,
                          hasPanel: hasPanel,
                          customIcon: isPenGroup &&
                                  penTools.contains(currentTool)
                              ? ToolButton.getIconForTool(currentTool)
                              : null,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: toolButton,
                        );
                      }),
                      // Settings button - after all tools (inside scrollable)
                      Padding(
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
                                if (current == ToolType.toolbarSettings) {
                                  ref.read(activePanelProvider.notifier).state = null;
                                } else {
                                  ref.read(activePanelProvider.notifier).state = ToolType.toolbarSettings;
                                }
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
                      ),
                    ],
                  ),
                ),
              ),

              // Quick access (conditionally on larger screens)
              if (showQuickAccess && constraints.maxWidth > 700) ...[
                const ToolbarVerticalDivider(),
                const Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: QuickAccessRow(),
                  ),
                ),
              ],

              const SizedBox(width: 4),
            ],
          );
        },
      ),
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
              ? currentTool
              : ToolType.ballpointPen);
          penAdded = true;
        }
      } else if (highlighterTools.contains(tool)) {
        if (!highlighterAdded) {
          result.add(highlighterTools.contains(currentTool)
              ? currentTool
              : ToolType.highlighter);
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
    ref.read(currentToolProvider.notifier).state = tool;
    ref.read(activePanelProvider.notifier).state = null;
  }

  void _onPanelTap(ToolType tool) {
    final active = ref.read(activePanelProvider);
    ref.read(activePanelProvider.notifier).state = active == tool ? null : tool;
  }

  GlobalKey? getToolButtonKey(ToolType tool) => _toolButtonKeys[tool];
}
