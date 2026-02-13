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

  /// Expanded toolbar layout — full horizontal bar with all sections visible.
  ///
  /// Used for >=840px screens (tablet landscape).
  /// Future: medium and compact layouts will be added as separate methods.
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
                        final isPenGroup = _isPen(tool);
                        final isHighlighterGroup = _isHighlighter(tool);
                        final isSelected = _isToolSelected(tool, currentTool);
                        final hasPanel = toolsWithPanel.contains(tool);

                        // Get GlobalKey for this tool button
                        // Pen tools share a single key, same for highlighters
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
                          onPanelTap: hasPanel ? () => _onPanelTap(tool) : null,
                          hasPanel: hasPanel,
                          customIcon: isPenGroup && _isPen(currentTool)
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

  /// Görünür araçları al, kalem ve fosforlu araçları ayrı grupla
  List<ToolType> _getGroupedVisibleTools(ToolbarConfig config, ToolType currentTool) {
    final visibleTools = config.visibleTools
        .map((toolConfig) => toolConfig.toolType)
        .toList();

    final result = <ToolType>[];
    bool penGroupAdded = false;
    bool highlighterGroupAdded = false;

    for (final tool in visibleTools) {
      if (_isPen(tool)) {
        if (!penGroupAdded) {
          // Aktif kalem aracını ekle, yoksa ballpointPen
          if (_isPen(currentTool)) {
            result.add(currentTool);
          } else {
            result.add(ToolType.ballpointPen);
          }
          penGroupAdded = true;
        }
        // Diğer kalem araçlarını atla
      } else if (_isHighlighter(tool)) {
        if (!highlighterGroupAdded) {
          // Aktif fosforlu aracını ekle, yoksa highlighter
          if (_isHighlighter(currentTool)) {
            result.add(currentTool);
          } else {
            result.add(ToolType.highlighter);
          }
          highlighterGroupAdded = true;
        }
        // Diğer fosforlu araçlarını atla
      } else {
        result.add(tool);
      }
    }

    return result;
  }

  bool _isToolSelected(ToolType tool, ToolType currentTool) {
    // Kalem grubu için: herhangi bir kalem aracı seçiliyse grup seçili
    if (_isPen(tool) && _isPen(currentTool)) {
      return true;
    }
    // Fosforlu grubu için: herhangi bir fosforlu aracı seçiliyse grup seçili
    if (_isHighlighter(tool) && _isHighlighter(currentTool)) {
      return true;
    }
    return tool == currentTool;
  }

  bool _isPen(ToolType tool) {
    return penTools.contains(tool);
  }

  bool _isHighlighter(ToolType tool) {
    return highlighterTools.contains(tool);
  }

  void _onToolPressed(ToolType tool) {
    ref.read(currentToolProvider.notifier).state = tool;
    ref.read(activePanelProvider.notifier).state = null;
  }

  /// Chevron'a tıklayınca panel aç/kapat
  void _onPanelTap(ToolType tool) {
    final activePanel = ref.read(activePanelProvider);
    if (activePanel == tool) {
      ref.read(activePanelProvider.notifier).state = null;
    } else {
      ref.read(activePanelProvider.notifier).state = tool;
    }
  }

  GlobalKey? getToolButtonKey(ToolType tool) => _toolButtonKeys[tool];
}
