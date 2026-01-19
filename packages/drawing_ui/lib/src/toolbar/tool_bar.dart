import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/quick_access_row.dart';

/// Tool bar (Row 2) - Drawing tools and quick access.
///
/// Contains:
/// - Undo/Redo buttons
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
  });

  /// Callback when undo is pressed.
  final VoidCallback? onUndoPressed;

  /// Callback when redo is pressed.
  final VoidCallback? onRedoPressed;

  /// Callback when toolbar config is pressed.
  final VoidCallback? onSettingsPressed;

  @override
  ConsumerState<ToolBar> createState() => _ToolBarState();
}

class _ToolBarState extends ConsumerState<ToolBar> {
  final Map<ToolType, GlobalKey> _toolButtonKeys = {};

  /// Kalem araçları (tek ikon olarak grupla) - panel'de hepsi görünür
  static const _penTools = [
    ToolType.pencil,
    ToolType.hardPencil,
    ToolType.ballpointPen,
    ToolType.gelPen,
    ToolType.dashedPen,
    ToolType.brushPen,
    ToolType.rulerPen,
  ];

  /// Fosforlu kalem araçları (ayrı ikon) - panel'de görünür
  static const _highlighterTools = [
    ToolType.highlighter,
    ToolType.neonHighlighter,
  ];

  /// Panel'i olan araçlar
  static const _toolsWithPanel = {
    ToolType.pencil,
    ToolType.hardPencil,
    ToolType.ballpointPen,
    ToolType.gelPen,
    ToolType.dashedPen,
    ToolType.brushPen,
    ToolType.neonHighlighter,
    ToolType.highlighter,
    ToolType.pixelEraser,
    ToolType.strokeEraser,
    ToolType.lassoEraser,
    ToolType.shapes,
    ToolType.sticker,
    ToolType.image,
    ToolType.laserPointer,
    ToolType.selection,
  };

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

    return Container(
      height: 46, // Normal yükseklik
      decoration: BoxDecoration(
        color: theme.toolbarBackground,
        border: Border(
          bottom: BorderSide(
            color: theme.panelBorderColor.withAlpha(80),
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
              _UndoRedoButtons(
                canUndo: canUndo,
                canRedo: canRedo,
                onUndo: widget.onUndoPressed,
                onRedo: widget.onRedoPressed,
              ),

              // Divider
              _VerticalDivider(),

              // Tools section (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: visibleTools.map((tool) {
                      final isPenGroup = _isPenTool(tool);
                      final isSelected = _isToolSelected(tool, currentTool);
                      final hasPanel = _toolsWithPanel.contains(tool);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ToolButton(
                          toolType: tool,
                          isSelected: isSelected,
                          buttonKey: _toolButtonKeys[tool],
                          onPressed: () => _onToolPressed(tool),
                          onPanelTap: hasPanel ? () => _onPanelTap(tool) : null,
                          hasPanel: hasPanel,
                          // Kalem grubu için aktif kalem ikonunu göster
                          customIcon: isPenGroup && _isPenTool(currentTool)
                              ? ToolButton.getIconForTool(currentTool)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Quick access (only on larger screens)
              if (showQuickAccess) ...[
                _VerticalDivider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: QuickAccessRow(),
                ),
              ],

              // Divider before settings
              _VerticalDivider(),

              // Toolbar config button - ALWAYS visible
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune, size: 24),
                  color: Colors.blue,
                  onPressed: () {
                    print('🔧 Settings button tapped!');
                    widget.onSettingsPressed?.call();
                    _openToolbarEditor();
                  },
                  tooltip: 'Araç Çubuğu Ayarları',
                ),
              ),

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
      if (_isPenTool(tool)) {
        if (!penGroupAdded) {
          // Aktif kalem aracını ekle, yoksa ballpointPen
          if (_isPenTool(currentTool)) {
            result.add(currentTool);
          } else {
            result.add(ToolType.ballpointPen);
          }
          penGroupAdded = true;
        }
        // Diğer kalem araçlarını atla
      } else if (_isHighlighterTool(tool)) {
        if (!highlighterGroupAdded) {
          // Aktif fosforlu aracını ekle, yoksa highlighter
          if (_isHighlighterTool(currentTool)) {
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
    if (_isPenTool(tool) && _isPenTool(currentTool)) {
      return true;
    }
    // Fosforlu grubu için: herhangi bir fosforlu aracı seçiliyse grup seçili
    if (_isHighlighterTool(tool) && _isHighlighterTool(currentTool)) {
      return true;
    }
    return tool == currentTool;
  }

  bool _isPenTool(ToolType tool) {
    return _penTools.contains(tool);
  }

  bool _isHighlighterTool(ToolType tool) {
    return _highlighterTools.contains(tool);
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

  void _openToolbarEditor() {
    final activePanel = ref.read(activePanelProvider);
    if (activePanel == ToolType.toolbarSettings) {
      ref.read(activePanelProvider.notifier).state = null;
    } else {
      ref.read(activePanelProvider.notifier).state = ToolType.toolbarSettings;
    }
  }

  GlobalKey? getToolButtonKey(ToolType tool) => _toolButtonKeys[tool];
}

/// Undo/Redo button group.
class _UndoRedoButtons extends StatelessWidget {
  const _UndoRedoButtons({
    required this.canUndo,
    required this.canRedo,
    this.onUndo,
    this.onRedo,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolbarIconButton(
          icon: Icons.undo,
          tooltip: 'Geri al',
          enabled: canUndo,
          onPressed: onUndo,
        ),
        const SizedBox(width: 4),
        _ToolbarIconButton(
          icon: Icons.redo,
          tooltip: 'İleri al',
          enabled: canRedo,
          onPressed: onRedo,
        ),
      ],
    );
  }
}

/// Vertical divider for toolbar sections.
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.panelBorderColor,
    );
  }
}

/// Toolbar config button.
class _ConfigButton extends StatelessWidget {
  const _ConfigButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Tooltip(
      message: 'Araç çubuğunu düzenle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.tune,
              size: 22,
              color: theme.toolbarIconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Generic toolbar icon button.
class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? theme.toolbarIconColor
                  : theme.toolbarIconColor.withAlpha(100),
            ),
          ),
        ),
      ),
    );
  }
}
