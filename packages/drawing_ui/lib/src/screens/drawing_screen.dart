import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/providers/pdf_prefetch_provider.dart';
import 'package:drawing_ui/src/toolbar/toolbar.dart';
import 'package:drawing_ui/src/canvas/canvas.dart';
import 'package:drawing_ui/src/canvas/infinite_background_painter.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/screens/drawing_screen_panels.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';

/// The main drawing screen that combines all UI components.
class DrawingScreen extends ConsumerStatefulWidget {
  const DrawingScreen({
    super.key,
    this.documentTitle,
    this.canvasMode,
    this.onHomePressed,
    this.onTitlePressed,
    this.onDocumentChanged,
  });

  /// Document title to display in TopNavigationBar.
  final String? documentTitle;

  /// Canvas mode (infinite/limited, page boundaries, etc.).
  final core.CanvasMode? canvasMode;

  /// Callback when home button is pressed.
  final VoidCallback? onHomePressed;

  /// Callback when document title is pressed (opens menu).
  final VoidCallback? onTitlePressed;

  /// Callback when document changes (for auto-save).
  final ValueChanged<dynamic>? onDocumentChanged;

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
  
  // Sidebar state for page navigator
  bool _isSidebarOpen = false;

  @override
  void dispose() {
    _panelController.dispose();
    _thumbnailCache.clear();
    super.dispose();
  }

  /// Toggle sidebar with animation completion callback
  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
    
    // Animasyon bittikten sonra canvas'ı yeniden hesapla
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _recalculateCanvasTransform();
      }
    });
  }

  /// Close sidebar (for mobile backdrop tap)
  void _closeSidebar() {
    setState(() {
      _isSidebarOpen = false;
    });
    
    // Animasyon bittikten sonra canvas'ı yeniden hesapla
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _recalculateCanvasTransform();
      }
    });
  }

  /// Recalculate canvas transform after sidebar toggle
  void _recalculateCanvasTransform() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTabletOrDesktop = screenWidth >= 600;
    final showSidebar = _isSidebarOpen && ref.read(pageCountProvider) > 1;

    // Calculate actual canvas viewport size
    final sidebarWidth = (isTabletOrDesktop && showSidebar) ? 140.0 : 0.0;
    final canvasWidth = screenWidth - sidebarWidth;
    final viewportSize = Size(canvasWidth, screenHeight);

    // Get current page
    final currentPage = ref.read(currentPageProvider);
    final pageSize = Size(currentPage.size.width, currentPage.size.height);

    // Re-initialize canvas transform with correct viewport
    final canvasMode = widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (!canvasMode.isInfinite) {
      ref.read(canvasTransformProvider.notifier).initializeForPage(
        viewportSize: viewportSize,
        pageSize: pageSize,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to activePanel changes
    ref.listen<ToolType?>(activePanelProvider, (previous, next) {
      _handlePanelChange(next);
    });
    
    // CRITICAL FIX: Dynamic PDF Prefetch - sayfa değiştiğinde otomatik prefetch
    ref.listen<core.DrawingDocument>(documentProvider, (previous, current) {
      if (previous != null && previous.currentPageIndex != current.currentPageIndex) {
        // Sayfa değişti, prefetch tetikle
        debugPrint('🔄 Page changed: ${previous.currentPageIndex} → ${current.currentPageIndex}');
        
        // PDF sayfalarını kontrol et
        final hasPdfPages = current.pages.any((p) =>
          p.background.type == core.BackgroundType.pdf &&
          p.background.pdfFilePath != null
        );
        
        if (hasPdfPages) {
          // Prefetch manager'ı tetikle
          final manager = ref.read(pdfPrefetchManagerProvider);
          manager.prefetchAround(
            currentPageIndex: current.currentPageIndex,
            allPages: current.pages,
          );
        }

        // Canvas transform'u yeniden hesapla (sayfa boyutu değişmiş olabilir)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _recalculateCanvasTransform();
          }
        });
      }
    });

    // Get canvas background color and transform for infinite background
    final currentPage = ref.watch(currentPageProvider);
    final bgColor = currentPage.background.color;
    final transform = ref.watch(canvasTransformProvider);
    
    // Canvas mode configuration
    final canvasMode = widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    
    // Scaffold background: Limited mode için surrounding area color, infinite için page color
    final scaffoldBgColor = canvasMode.isInfinite 
        ? Color(bgColor) 
        : Color(canvasMode.surroundingAreaColor);

    // Get Material theme colors
    final materialTheme = Theme.of(context);
    final colorScheme = materialTheme.colorScheme;
    final isDark = materialTheme.brightness == Brightness.dark;
    
    // Create theme-aware DrawingTheme
    final drawingTheme = DrawingTheme(
      toolbarBackground: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
      toolbarIconColor: colorScheme.onSurfaceVariant,
      toolbarIconSelectedColor: colorScheme.primary,
      toolbarIconDisabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
      panelBackground: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
      panelBorderColor: colorScheme.outlineVariant,
      penBoxBackground: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
      penBoxSlotSelectedColor: colorScheme.primaryContainer,
    );

    // Responsive: Tablet/Desktop vs Mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth >= 600;
    final showSidebar = _isSidebarOpen && ref.watch(pageCountProvider) > 1;

    return DrawingThemeProvider(
      theme: drawingTheme,
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        body: SafeArea(
          child: Stack(
            children: [
              // Main content (always full width)
              Column(
                children: [
                  // Row 1: Top navigation bar (full width)
                  TopNavigationBar(
                    documentTitle: widget.documentTitle,
                    onHomePressed: widget.onHomePressed,
                    onTitlePressed: widget.onTitlePressed,
                  ),

                  // Row 2: Tool bar (full width, hamburger icon ile)
                  ToolBar(
                    onUndoPressed: _onUndoPressed,
                    onRedoPressed: _onRedoPressed,
                    onSettingsPressed: _onSettingsPressed,
                    settingsButtonKey: _settingsButtonKey,
                    toolButtonKeys: _toolButtonKeys,
                    penGroupButtonKey: _penGroupButtonKey,
                    highlighterGroupButtonKey: _highlighterGroupButtonKey,
                    // Hamburger button (GoodNotes style)
                    showSidebarButton: ref.watch(pageCountProvider) > 1,
                    isSidebarOpen: _isSidebarOpen,
                    onSidebarToggle: _toggleSidebar,
                  ),

                  // Row 3: Canvas area
                  Expanded(
                    child: Row(
                      children: [
                        // TABLET/DESKTOP: Animated sidebar (yan yana)
                        if (isTabletOrDesktop)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: showSidebar ? 140.0 : 0.0,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: showSidebar ? 1.0 : 0.0,
                              child: showSidebar
                                  ? _buildSidebar()
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        
                        // Canvas area (always present)
                        Expanded(child: _buildCanvasArea(context, currentPage, transform)),
                      ],
                    ),
                  ),
                ],
              ),

              // Mobile backdrop (tap to close) - ÖNCE
              if (!isTabletOrDesktop && showSidebar)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeSidebar,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: showSidebar ? 0.5 : 0.0,
                      child: Container(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              
              // MOBILE OVERLAY: Sidebar (drawer tarzı) - Animated - SONRA
              if (!isTabletOrDesktop)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: showSidebar ? 0 : -140,
                  top: 0,
                  bottom: 0,
                  width: 140,
                  child: _buildSidebar(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Canvas area with all layers (background, canvas, panels, etc.)
  Widget _buildCanvasArea(BuildContext context, core.Page currentPage, CanvasTransform transform) {
    return Stack(
      children: [
        // LAYER 0: Infinite Background (zoom ile ölçeklenir, tüm ekranı kaplar)
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: InfiniteBackgroundPainter(
                background: currentPage.background,
                zoom: transform.zoom,
                offset: transform.offset,
              ),
              size: Size.infinite,
            ),
          ),
        ),

        // LAYER 1: Drawing Canvas (zoom/pan transform içinde)
        Positioned.fill(
          child: DrawingCanvas(
            canvasMode: widget.canvasMode,
          ),
        ),

        // Invisible tap barrier to close panel when tapping canvas
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

        // Zoom indicator (center, visible only while zooming)
        if (ref.watch(isZoomingProvider))
          Center(
            child: _ZoomIndicator(
              zoomPercentage: ref.watch(zoomPercentageProvider),
            ),
          ),
      ],
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
  Widget _buildSidebar() {
    final pageManager = ref.watch(pageManagerProvider);
    final pageCount = ref.watch(pageCountProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 140, // GoodNotes gibi kompakt
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // HEADER YOK - Direkt thumbnails başlıyor (GoodNotes gibi)
          
          // Page thumbnails (vertical scroll) - GoodNotes style
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 16),
              itemCount: pageCount,
              itemBuilder: (context, index) {
                // Page thumbnail
                final page = pageManager.pages[index];
                final isSelected = index == pageManager.currentIndex;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20), // GoodNotes spacing
                  child: GestureDetector(
                    onTap: () {
                      // PageManager'ı güncelle
                      ref.read(pageManagerProvider.notifier).goToPage(index);
                      
                      // CRITICAL FIX: DocumentProvider'ı da senkronize et
                      final document = ref.read(documentProvider);
                      if (document.isMultiPage && document.currentPageIndex != index) {
                        final updatedDoc = document.setCurrentPage(index);
                        ref.read(documentProvider.notifier).updateDocument(updatedDoc);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Thumbnail card - GoodNotes exact style
                        Container(
                          height: 152, // GoodNotes boyut
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
                            borderRadius: BorderRadius.circular(8), // GoodNotes: 8px
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isSelected ? 0.12 : 0.06),
                                blurRadius: isSelected ? 8 : 4,
                                offset: Offset(0, isSelected ? 2 : 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: PageThumbnail(
                              page: page,
                              cache: _thumbnailCache,
                              width: 116,
                              height: 152,
                              isSelected: isSelected,
                              showPageNumber: false,
                            ),
                          ),
                        ),
                        
                        // Page number (minimal, GoodNotes style)
                        const SizedBox(height: 6),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Add button (en alta sabitlenmiş - GoodNotes gibi)
          _buildAddPageButton(),
        ],
      ),
    );
  }
  
  Widget _buildAddPageButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          ref.read(pageManagerProvider.notifier).addPage();
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 20,
                color: colorScheme.primary,
              ),
              if (screenWidth > 600) ...[
                const SizedBox(width: 6),
                Text(
                  'Sayfa Ekle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
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

/// Zoom indicator shown in center while zooming.
class _ZoomIndicator extends StatelessWidget {
  const _ZoomIndicator({required this.zoomPercentage});

  final String zoomPercentage;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          zoomPercentage,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
