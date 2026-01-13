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
///
/// This is the primary widget for the drawing experience.
/// Phase 1: UI skeleton only - no real drawing logic.
class DrawingScreen extends ConsumerStatefulWidget {
  const DrawingScreen({super.key});

  @override
  ConsumerState<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends ConsumerState<DrawingScreen> {
  // Keys for anchoring panels
  final Map<ToolType, GlobalKey> _toolButtonKeys = {};
  final GlobalKey _toolbarKey = GlobalKey();

  // Pen box position (draggable when collapsed)
  Offset _penBoxPosition = const Offset(12, 12);

  @override
  void initState() {
    super.initState();
    for (final tool in ToolType.values) {
      _toolButtonKeys[tool] = GlobalKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePanel = ref.watch(activePanelProvider);

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
                key: _toolbarKey,
                onUndoPressed: _onUndoPressed,
                onRedoPressed: _onRedoPressed,
                onSettingsPressed: _onSettingsPressed,
              ),

              // Canvas area with floating elements
              Expanded(
                child: Stack(
                  children: [
                    // Full width canvas
                    const Positioned.fill(
                      child: MockCanvas(),
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

                    // Tap barrier to close panels
                    if (activePanel != null)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _closePanel,
                          behavior: HitTestBehavior.translucent,
                          child: const SizedBox.expand(),
                        ),
                      ),

                    // Floating panel (left side, offset for pen box)
                    if (activePanel != null)
                      Positioned(
                        left: 70,
                        top: 16,
                        child: _buildActivePanel(activePanel),
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

  Widget _buildActivePanel(ToolType panel) {
    switch (panel) {
      case ToolType.ballpointPen:
      case ToolType.fountainPen:
      case ToolType.pencil:
      case ToolType.brush:
        return PenSettingsPanel(
          toolType: panel,
          onClose: _closePanel,
        );

      case ToolType.highlighter:
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
        // Using selection type as placeholder for toolbar editor
        return ToolbarEditorPanel(onClose: _closePanel);

      case ToolType.laserPointer:
        return _LaserPointerPanel(onClose: _closePanel);

      case ToolType.text:
        return _TextToolPanel(onClose: _closePanel);

      case ToolType.panZoom:
        return const SizedBox.shrink();
    }
  }

  void _onUndoPressed() {
    // MOCK: Would trigger undo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MOCK: Undo (will be implemented in Phase 2)'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onRedoPressed() {
    // MOCK: Would trigger redo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MOCK: Redo (will be implemented in Phase 2)'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onSettingsPressed() {
    final current = ref.read(activePanelProvider);
    if (current == ToolType.selection) {
      _closePanel();
    } else {
      ref.read(activePanelProvider.notifier).state = ToolType.selection;
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
