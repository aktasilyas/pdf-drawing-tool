import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/toolbar/toolbar.dart';
import 'package:drawing_ui/src/canvas/page_slide_transition.dart';
import 'package:drawing_ui/src/screens/drawing_screen_layout.dart';
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

  final String? documentTitle;
  final core.CanvasMode? canvasMode;
  final VoidCallback? onHomePressed;
  final VoidCallback? onTitlePressed;
  final ValueChanged<dynamic>? onDocumentChanged;

  @override
  ConsumerState<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends ConsumerState<DrawingScreen> {
  final Map<ToolType, GlobalKey> _toolButtonKeys = {for (final tool in ToolType.values) tool: GlobalKey()};
  final GlobalKey _penGroupButtonKey = GlobalKey();
  final GlobalKey _highlighterGroupButtonKey = GlobalKey();
  final GlobalKey _settingsButtonKey = GlobalKey();
  final GlobalKey<PageSlideTransitionState> _pageTransitionKey = GlobalKey<PageSlideTransitionState>();
  final PopoverController _panelController = PopoverController();
  final ThumbnailCache _thumbnailCache = ThumbnailCache(maxSize: 20);
  Offset _penBoxPosition = const Offset(12, 12);
  bool _isSidebarOpen = false;
  bool _isPageTransitioning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = MediaQuery.platformBrightnessOf(context);
    ref.read(platformBrightnessProvider.notifier).state = brightness;
  }

  @override
  void dispose() {
    _panelController.dispose();
    _thumbnailCache.clear();
    super.dispose();
  }

  Future<void> _navigateToPage(int targetIndex) async {
    final currentIndex = ref.read(currentPageIndexProvider);
    if (targetIndex == currentIndex || _isPageTransitioning) return;
    _isPageTransitioning = true;
    try {
      final forward = targetIndex > currentIndex;
      await _pageTransitionKey.currentState?.captureSnapshot(forward: forward);
      ref.read(pageManagerProvider.notifier).goToPage(targetIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageTransitionKey.currentState?.startAnimation();
        _isPageTransitioning = false;
      });
    } catch (_) {
      _isPageTransitioning = false;
    }
  }

  void _toggleSidebar() {
    setState(() => _isSidebarOpen = !_isSidebarOpen);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _recalculateCanvasTransform();
    });
  }

  void _closeSidebar() {
    setState(() => _isSidebarOpen = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _recalculateCanvasTransform();
    });
  }

  void _recalculateCanvasTransform() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= ToolbarLayoutMode.compactBreakpoint;
    final showSidebar = _isSidebarOpen && ref.read(pageCountProvider) > 1;
    final sidebarWidth = (isTablet && showSidebar) ? kPageSidebarWidth : 0.0;
    final viewportSize = Size(size.width - sidebarWidth, size.height);
    final currentPage = ref.read(currentPageProvider);
    final pageSize = Size(currentPage.size.width, currentPage.size.height);
    final canvasMode = widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (!canvasMode.isInfinite) {
      ref.read(canvasTransformProvider.notifier).recenterForViewport(
        viewportSize: viewportSize,
        pageSize: pageSize,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to activePanel changes
    ref.listen<ToolType?>(activePanelProvider, (previous, next) {
      final isPenPickerMode = ref.read(penPickerModeProvider);
      handlePanelChange(
        context: context,
        panel: next,
        panelController: _panelController,
        toolButtonKeys: _toolButtonKeys,
        penGroupButtonKey: _penGroupButtonKey,
        highlighterGroupButtonKey: _highlighterGroupButtonKey,
        settingsButtonKey: _settingsButtonKey,
        onClosePanel: _closePanel,
        isPenPickerMode: isPenPickerMode,
        onPenSelected: _onPenSelected,
      );
    });

    // Sync page index from PageManager → DocumentProvider.
    // This ensures all navigation sources (indicator bar, swipe, sidebar)
    // keep the document's currentPageIndex in sync for correct auto-save.
    ref.listen<int>(currentPageIndexProvider, (previous, current) {
      if (previous != null && previous != current) {
        final doc = ref.read(documentProvider);
        if (doc.isMultiPage && doc.currentPageIndex != current) {
          ref.read(documentProvider.notifier).updateDocument(doc.setCurrentPage(current));
        }
      }
    });

    // Listen to document changes for PDF prefetch and canvas transform
    ref.listen<core.DrawingDocument>(documentProvider, (previous, current) {
      if (previous != null && previous.currentPageIndex != current.currentPageIndex) {
        _handleDocumentPageChange(current);
      }
    });

    final isReaderMode = ref.watch(readerModeProvider);
    final currentPage = ref.watch(currentPageProvider);
    final transform = ref.watch(canvasTransformProvider);
    final canvasMode = widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    final materialTheme = Theme.of(context);
    final colorScheme = materialTheme.colorScheme;
    final isDark = materialTheme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactMode = screenWidth < ToolbarLayoutMode.compactBreakpoint;
    final showSidebar = _isSidebarOpen && ref.watch(pageCountProvider) > 1;

    final scaffoldBgColor = canvasMode.isInfinite
        ? Color(currentPage.background.color)
        : Color(canvasMode.surroundingAreaColor);

    final drawingTheme = DrawingTheme(
      toolbarBackground: colorScheme.surface,
      toolbarIconColor: colorScheme.onSurfaceVariant,
      toolbarIconSelectedColor: colorScheme.primary,
      toolbarIconDisabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
      panelBackground: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surface,
      panelBorderColor: colorScheme.outlineVariant,
      penBoxBackground: colorScheme.surface,
      penBoxSlotSelectedColor: colorScheme.primaryContainer,
    );

    return DrawingThemeProvider(
      theme: drawingTheme,
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        // Phone: bottom bar
        bottomNavigationBar: isCompactMode && !isReaderMode
            ? CompactBottomBar(
                onUndoPressed: _onUndoPressed,
                onRedoPressed: _onRedoPressed,
                onPanelRequested: (tool) {
                  showToolPanelSheet(context: context, tool: tool);
                },
              )
            : null,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  AdaptiveToolbar(
                    onSettingsPressed: _onSettingsPressed,
                    settingsButtonKey: _settingsButtonKey,
                    toolButtonKeys: _toolButtonKeys,
                    penGroupButtonKey: _penGroupButtonKey,
                    highlighterGroupButtonKey: _highlighterGroupButtonKey,
                    documentTitle: widget.documentTitle,
                    onHomePressed: widget.onHomePressed,
                    onTitlePressed: widget.onTitlePressed,
                    onSidebarToggle: _toggleSidebar,
                    isSidebarOpen: _isSidebarOpen,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        if (isCompactMode == false)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: showSidebar ? kPageSidebarWidth : 0.0,
                            clipBehavior: Clip.hardEdge,
                            decoration: const BoxDecoration(),
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              maxWidth: kPageSidebarWidth,
                              minWidth: kPageSidebarWidth,
                              child: PageSidebar(
                                thumbnailCache: _thumbnailCache,
                                onPageTap: _navigateToPage,
                              ),
                            ),
                          ),
                        Expanded(
                          child: buildDrawingCanvasArea(
                            context: context,
                            ref: ref,
                            currentPage: currentPage,
                            transform: transform,
                            canvasMode: widget.canvasMode,
                            penBoxPosition: _penBoxPosition,
                            onPenBoxPositionChanged: (p) => setState(() => _penBoxPosition = p),
                            onClosePanel: _closePanel,
                            onOpenAIPanel: () => openAIPanel(context),
                            pageTransitionKey: _pageTransitionKey,
                            onPageChanged: _navigateToPage,
                            colorScheme: ref.watch(canvasColorSchemeProvider),
                            isReadOnly: isReaderMode,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isCompactMode && showSidebar)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeSidebar,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: 0.5,
                      child: Container(color: Colors.black),
                    ),
                  ),
                ),
              if (isCompactMode)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: showSidebar ? 0 : -kPageSidebarWidth,
                  top: 0,
                  bottom: 0,
                  width: kPageSidebarWidth,
                  child: PageSidebar(thumbnailCache: _thumbnailCache, onPageTap: _navigateToPage),
                ),
            ],
          ),
        ),
      ),
    );
  }
  void _handleDocumentPageChange(core.DrawingDocument current) {
    final hasPdfPages = current.pages.any(
        (p) => p.background.type == core.BackgroundType.pdf && p.background.pdfFilePath != null);
    if (hasPdfPages) {
      ref.read(pdfPrefetchManagerProvider).prefetchAround(
        currentPageIndex: current.currentPageIndex,
        allPages: current.pages,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recalculateCanvasTransform();
    });
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

  void _closePanel() {
    ref.read(activePanelProvider.notifier).state = null;
    ref.read(penPickerModeProvider.notifier).state = false;
  }

  void _onPenSelected(ToolType selectedPen) {
    // Close picker
    ref.read(penPickerModeProvider.notifier).state = false;
    ref.read(activePanelProvider.notifier).state = null;
    // Open settings panel after brief delay
    Future.microtask(() {
      if (mounted) {
        ref.read(activePanelProvider.notifier).state = selectedPen;
      }
    });
  }


}
