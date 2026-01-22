import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/toolbar/toolbar.dart';
import 'package:drawing_ui/src/canvas/canvas.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/screens/drawing_screen_panels.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';

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

  // Thumbnail cache for page navigator
  final ThumbnailCache _thumbnailCache = ThumbnailCache(maxSize: 20);

  @override
  void dispose() {
    _panelController.dispose();
    _thumbnailCache.clear();
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
                child: Column(
                  children: [
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

                    // Page Navigator (bottom bar)
                    _buildPageNavigator(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      } else if (drawingScreenPenTools.contains(panel)) {
        anchorKey = _penGroupButtonKey;
      } else if (drawingScreenHighlighterTools.contains(panel)) {
        anchorKey = _highlighterGroupButtonKey;
      } else {
        anchorKey = _toolButtonKeys[panel] ?? GlobalKey();
      }

      // Determine alignment based on tool position in toolbar
      final alignment = resolvePanelAlignment(panel);

      // Use post-frame callback to ensure button is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _panelController.show(
            context: context,
            anchorKey: anchorKey,
            alignment: alignment,
            verticalOffset: 8,
            onBarrierTap: _closePanel,
            child: buildActivePanel(
              panel: panel,
              onClose: _closePanel,
            ),
          );
        }
      });
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

  /// Builds the page navigator widget.
  Widget _buildPageNavigator() {
    final pageManager = ref.watch(pageManagerProvider);
    final pageCount = ref.watch(pageCountProvider);

    // Only show if there are multiple pages
    if (pageCount <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: PageNavigator(
        pageManager: pageManager,
        cache: _thumbnailCache,
        onPageChanged: (index) {
          ref.read(pageManagerProvider.notifier).goToPage(index);
        },
        onAddPage: () {
          ref.read(pageManagerProvider.notifier).addPage();
        },
        onDeletePage: (index) {
          ref.read(pageManagerProvider.notifier).deletePage(index);
        },
        onDuplicatePage: (index) {
          ref.read(pageManagerProvider.notifier).duplicatePage(index);
        },
      ),
    );
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
