import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/toolbar/toolbar.dart';
import 'package:drawing_ui/src/canvas/canvas.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';

/// The main drawing screen that combines all UI components.
class DrawingScreen extends ConsumerStatefulWidget {
  const DrawingScreen({super.key});

  @override
  ConsumerState<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends ConsumerState<DrawingScreen> {
  // GlobalKeys for anchored panels - one per tool type
  final Map<ToolType, GlobalKey> _toolButtonKeys = {
    for (final tool in ToolType.values) tool: GlobalKey(),
  };

  // Single GlobalKey for pen group (all pen tools share this button)
  final GlobalKey _penGroupButtonKey = GlobalKey();

  // Single GlobalKey for highlighter group
  final GlobalKey _highlighterGroupButtonKey = GlobalKey();

  // Settings button has its own GlobalKey
  final GlobalKey _settingsButtonKey = GlobalKey();

  // Panel controller for overlay-based panels
  final AnchoredPanelController _panelController = AnchoredPanelController();

  // Pen box position (draggable when collapsed)
  Offset _penBoxPosition = const Offset(12, 12);

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to activePanel changes
    ref.listen<ToolType?>(activePanelProvider, (previous, next) {
      _handlePanelChange(next);
    });

    return DrawingThemeProvider(
      theme: const DrawingTheme(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Row 1: Top navigation bar
              const TopNavigationBar(),

              // Row 2: Tool bar
              ToolBar(
                onUndoPressed: _onUndoPressed,
                onRedoPressed: _onRedoPressed,
                onSettingsPressed: _onSettingsPressed,
                settingsButtonKey: _settingsButtonKey,
                toolButtonKeys: _toolButtonKeys,
                penGroupButtonKey: _penGroupButtonKey,
                highlighterGroupButtonKey: _highlighterGroupButtonKey,
              ),

              // Canvas area with floating elements
              Expanded(
                child: Stack(
                  children: [
                    // Full width canvas - Real drawing canvas
                    const Positioned.fill(
                      child: DrawingCanvas(),
                    ),

                    // Invisible tap barrier to close panel when tapping canvas
                    // Uses onTap (not onTapDown) so drawing gestures are not affected
                    if (ref.watch(activePanelProvider) != null)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _closePanel,
                          child: const SizedBox.expand(),
                        ),
                      ),

                    // Floating pen box (draggable when collapsed)
                    Positioned(
                      left: _penBoxPosition.dx,
                      top: _penBoxPosition.dy,
                      child: FloatingPenBox(
                        position: _penBoxPosition,
                        onPositionChanged: (delta) {
                          setState(() {
                            _penBoxPosition += delta;
                            // Keep within bounds
                            _penBoxPosition = Offset(
                              _penBoxPosition.dx.clamp(
                                  0, MediaQuery.of(context).size.width - 60),
                              _penBoxPosition.dy.clamp(
                                  0, MediaQuery.of(context).size.height - 200),
                            );
                          });
                        },
                      ),
                    ),

                    // AI Assistant button (right bottom)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _AskAIButton(
                        onTap: _openAIPanel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pen tools that share the same LayerLink
  static const _penTools = {
    ToolType.pencil,
    ToolType.hardPencil,
    ToolType.ballpointPen,
    ToolType.gelPen,
    ToolType.dashedPen,
    ToolType.brushPen,
    ToolType.rulerPen,
  };

  // Highlighter tools that share the same LayerLink
  static const _highlighterTools = {
    ToolType.highlighter,
    ToolType.neonHighlighter,
  };

  /// Handle panel state changes - show/hide overlay
  void _handlePanelChange(ToolType? panel) {
    if (panel == null) {
      // Close panel
      _panelController.hide();
    } else if (panel != ToolType.panZoom) {
      // Show panel as overlay
      // Get the appropriate GlobalKey for this panel's button
      // Pen tools share a single button, same for highlighters
      final GlobalKey anchorKey;
      if (panel == ToolType.toolbarSettings) {
        anchorKey = _settingsButtonKey;
      } else if (_penTools.contains(panel)) {
        anchorKey = _penGroupButtonKey;
      } else if (_highlighterTools.contains(panel)) {
        anchorKey = _highlighterGroupButtonKey;
      } else {
        anchorKey = _toolButtonKeys[panel] ?? GlobalKey();
      }

      // Determine alignment based on tool position in toolbar
      final alignment = _getAlignmentForTool(panel);

      // Use post-frame callback to ensure button is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _panelController.show(
            context: context,
            anchorKey: anchorKey,
            alignment: alignment,
            verticalOffset: 8,
            onBarrierTap: _closePanel,
            child: _buildActivePanel(panel),
          );
        }
      });
    }
  }

  /// Determine panel alignment based on tool's position in toolbar
  AnchorAlignment _getAlignmentForTool(ToolType tool) {
    // Left-edge tools (first tools in toolbar) - align panel to left
    const leftTools = {
      ToolType.pencil,
      ToolType.hardPencil,
      ToolType.ballpointPen,
      ToolType.gelPen,
      ToolType.dashedPen,
      ToolType.brushPen,
      ToolType.rulerPen,
    };

    // Right-edge tools (last tools in toolbar) - align panel to right
    const rightTools = {
      ToolType.toolbarSettings,
      ToolType.laserPointer,
      ToolType.image,
    };

    if (leftTools.contains(tool)) {
      return AnchorAlignment.left;
    } else if (rightTools.contains(tool)) {
      return AnchorAlignment.right;
    }
    return AnchorAlignment.center;
  }

  Widget _buildActivePanel(ToolType panel) {
    switch (panel) {
      case ToolType.pencil:
      case ToolType.hardPencil:
      case ToolType.ballpointPen:
      case ToolType.gelPen:
      case ToolType.dashedPen:
      case ToolType.brushPen:
      case ToolType.rulerPen:
        return PenSettingsPanel(
          toolType: panel,
          onClose: _closePanel,
        );

      case ToolType.highlighter:
      case ToolType.neonHighlighter:
        return HighlighterSettingsPanel(onClose: _closePanel);

      case ToolType.pixelEraser:
      case ToolType.strokeEraser:
      case ToolType.lassoEraser:
        return EraserSettingsPanel(onClose: _closePanel);

      case ToolType.shapes:
        return ShapesSettingsPanel(onClose: _closePanel);

      case ToolType.sticker:
        return StickerPanel(onClose: _closePanel);

      case ToolType.image:
        return ImagePanel(onClose: _closePanel);

      case ToolType.selection:
        return LassoSelectionPanel(onClose: _closePanel);

      case ToolType.laserPointer:
        return _LaserPointerPanel(onClose: _closePanel);

      case ToolType.text:
        return _TextToolPanel(onClose: _closePanel);

      case ToolType.panZoom:
        return const SizedBox.shrink();

      case ToolType.toolbarSettings:
        return ToolbarSettingsPanel(onClose: _closePanel);
    }
  }

  void _onUndoPressed() {
    ref.read(historyManagerProvider.notifier).undo();
  }

  void _onRedoPressed() {
    ref.read(historyManagerProvider.notifier).redo();
  }

  void _onSettingsPressed() {
    final current = ref.read(activePanelProvider);
    if (current == ToolType.toolbarSettings) {
      _closePanel();
    } else {
      ref.read(activePanelProvider.notifier).state = ToolType.toolbarSettings;
    }
  }

  void _openAIPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: AIAssistantPanel(
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  void _closePanel() {
    ref.read(activePanelProvider.notifier).state = null;
  }
}

/// Floating AI button.
class _AskAIButton extends StatelessWidget {
  const _AskAIButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Simple text tool panel (placeholder).
class _TextToolPanel extends StatelessWidget {
  const _TextToolPanel({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ToolPanel(
      title: 'Text',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tap on the canvas to add a text box.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          PanelSection(
            title: 'FONT SIZE',
            child: Slider(
              value: 16,
              min: 8,
              max: 72,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 16),
          const PanelSection(
            title: 'TEXT COLOR',
            child: Row(
              children: [
                _ColorDot(color: Colors.black, isSelected: true),
                SizedBox(width: 8),
                _ColorDot(color: Colors.blue),
                SizedBox(width: 8),
                _ColorDot(color: Colors.red),
                SizedBox(width: 8),
                _ColorDot(color: Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple laser pointer panel (placeholder).
class _LaserPointerPanel extends StatelessWidget {
  const _LaserPointerPanel({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ToolPanel(
      title: 'Laser Pointer',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelSection(
            title: 'MODE',
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Dot',
                    icon: Icons.fiber_manual_record,
                    isSelected: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeButton(
                    label: 'Trail',
                    icon: Icons.gesture,
                    isSelected: false,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PanelSection(
            title: 'COLOR',
            child: Row(
              children: [
                _ColorDot(color: Colors.red, isSelected: true),
                SizedBox(width: 8),
                _ColorDot(color: Colors.green),
                SizedBox(width: 8),
                _ColorDot(color: Colors.blue),
                SizedBox(width: 8),
                _ColorDot(color: Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PanelSection(
            title: 'DURATION',
            child: Slider(
              value: 2,
              min: 0.5,
              max: 5,
              divisions: 9,
              label: '2s',
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple color dot widget.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    this.isSelected = false,
  });

  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 3 : 1,
        ),
      ),
    );
  }
}

/// Mode button for laser pointer.
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
