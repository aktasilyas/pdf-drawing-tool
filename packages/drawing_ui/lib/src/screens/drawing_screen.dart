import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/toolbar/toolbar.dart';
import 'package:drawing_ui/src/canvas/page_slide_transition.dart';
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
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
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onDocumentChanged,
    this.onAIPressed,
    this.externalLeftSidebar,
    this.isExternalLeftSidebarOpen = false,
    this.externalLeftSidebarWidth = 0.0,
    this.onExternalLeftSidebarClose,
  });

  final String? documentTitle;
  final core.CanvasMode? canvasMode;
  final VoidCallback? onHomePressed;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;
  final ValueChanged<dynamic>? onDocumentChanged;
  final VoidCallback? onAIPressed;

  /// Optional external left sidebar widget (e.g. AI chat).
  /// Rendered below the toolbar, to the left of the canvas area.
  final Widget? externalLeftSidebar;

  /// Whether the external left sidebar is open.
  final bool isExternalLeftSidebarOpen;

  /// Width of the external left sidebar.
  final double externalLeftSidebarWidth;

  /// Called when the phone overlay is tapped to dismiss the sidebar.
  final VoidCallback? onExternalLeftSidebarClose;

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
  bool _isPageTransitioning = false;
  int? _preSwitchPageIndex; // Original page index before interactive pre-switch

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = MediaQuery.platformBrightnessOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(platformBrightnessProvider.notifier).state = brightness;
      }
    });
  }

  @override
  void didUpdateWidget(DrawingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExternalLeftSidebarOpen !=
        widget.isExternalLeftSidebarOpen) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _recalculateCanvasTransform();
      });
    }
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

  /// Called when drag direction is determined. Pre-switches the page so the
  /// live child renders the target page. Returns true if pre-switch happened.
  bool _onDragDirectionDetermined(int direction) {
    final currentIdx = ref.read(currentPageIndexProvider);
    final count = ref.read(pageCountProvider);
    final targetIdx = currentIdx + direction;
    if (targetIdx >= 0 && targetIdx < count) {
      _preSwitchPageIndex = currentIdx;
      ref.read(pageManagerProvider.notifier).goToPage(targetIdx);
      return true;
    }
    return false; // Last page forward — can't pre-switch
  }

  /// Called when a pre-switched drag is cancelled. Reverts to original page.
  void _onDragReverted() {
    if (_preSwitchPageIndex != null) {
      ref.read(pageManagerProvider.notifier).goToPage(_preSwitchPageIndex!);
      _preSwitchPageIndex = null;
    }
  }

  /// Called when interactive swipe completes (only for non-pre-switched cases).
  void _handleSwipeNavigate(int direction) {
    if (_preSwitchPageIndex != null) {
      // Page was already pre-switched — just clear saved index
      _preSwitchPageIndex = null;
      return;
    }
    // Not pre-switched (e.g., last page forward) — handle normally
    final currentIndex = ref.read(currentPageIndexProvider);
    if (direction == 1) {
      final count = ref.read(pageCountProvider);
      if (currentIndex < count - 1) {
        ref.read(pageManagerProvider.notifier).goToPage(currentIndex + 1);
      } else {
        _addPageAfterLast();
      }
    } else if (direction == -1) {
      if (currentIndex > 0) {
        ref.read(pageManagerProvider.notifier).goToPage(currentIndex - 1);
      }
    }
  }

  /// Resolves the background for a new page added by swipe.
  /// If the current page is a built-in template, reuse it.
  /// Otherwise (PDF, cover, etc.) fall back to thin_lined template.
  core.PageBackground _resolveNewPageBackground() {
    final bg = ref.read(currentPageProvider).background;
    switch (bg.type) {
      case core.BackgroundType.template:
      case core.BackgroundType.blank:
      case core.BackgroundType.grid:
      case core.BackgroundType.lined:
      case core.BackgroundType.dotted:
        return bg;
      case core.BackgroundType.pdf:
      case core.BackgroundType.cover:
        final t = core.TemplateRegistry.getById('thin_lined')!;
        return core.PageBackground(
          type: core.BackgroundType.template,
          color: t.defaultBackgroundColor,
          templatePattern: t.pattern,
          templateSpacingMm: t.spacingMm,
          templateLineWidth: t.lineWidth,
          lineColor: t.defaultLineColor,
        );
    }
  }

  /// Adds a new page after the last page.
  void _addPageAfterLast() {
    final doc = ref.read(documentProvider);
    final newPage = core.Page.create(
      index: doc.pages.length,
      size: doc.settings.defaultPageSize,
      background: _resolveNewPageBackground(),
    );
    final newPages = List<core.Page>.from(doc.pages)..add(newPage);
    final newDoc = doc.copyWith(
      pages: newPages,
      currentPageIndex: newPages.length - 1,
    );
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
      newDoc.pages,
      currentIndex: newDoc.currentPageIndex,
    );
  }

  bool get _isSidebarOpen => ref.read(sidebarOpenProvider);

  void _toggleSidebar() {
    ref.read(sidebarOpenProvider.notifier).state = !_isSidebarOpen;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _recalculateCanvasTransform();
    });
  }

  void _closeSidebar() {
    ref.read(sidebarOpenProvider.notifier).state = false;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _recalculateCanvasTransform();
    });
  }

  void _recalculateCanvasTransform() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= ToolbarLayoutMode.compactBreakpoint;
    final showSidebar = _isSidebarOpen && ref.read(pageCountProvider) > 1;
    final sidebarWidth = (isTablet && showSidebar) ? kPageSidebarWidth : 0.0;
    final externalInset = (isTablet && widget.isExternalLeftSidebarOpen)
        ? widget.externalLeftSidebarWidth
        : 0.0;
    var canvasWidth = size.width - sidebarWidth - externalInset;
    // Use the actual canvas height from LayoutBuilder, not full screen height
    final canvasHeight = ref.read(canvasViewportSizeProvider).height;
    final viewportSize = Size(canvasWidth, canvasHeight > 0 ? canvasHeight : size.height);
    ref.read(canvasViewportSizeProvider.notifier).state = viewportSize;
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
    // Defer provider modification to after build completes
    final isInfinite = canvasMode.isInfinite;
    final aiCallback = widget.onAIPressed ?? () => openAIPanel(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(isInfiniteCanvasProvider.notifier).state = isInfinite;
        ref.read(onAIPressedCallbackProvider.notifier).state = aiCallback;
      }
    });
    final materialTheme = Theme.of(context);
    final colorScheme = materialTheme.colorScheme;
    final isDark = materialTheme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactMode = screenWidth < ToolbarLayoutMode.compactBreakpoint;
    final isSidebarOpen = ref.watch(sidebarOpenProvider);
    final showSidebar = isSidebarOpen && ref.watch(pageCountProvider) > 1;

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
        resizeToAvoidBottomInset: false,
        backgroundColor: scaffoldBgColor,
        body: SafeArea(
          top: !isCompactMode,
          child: Stack(
            children: [
              Column(
                children: [
                  AdaptiveToolbar(
                    onAIPressed: widget.onAIPressed ?? () => openAIPanel(context),
                    onSettingsPressed: _onSettingsPressed,
                    settingsButtonKey: _settingsButtonKey,
                    toolButtonKeys: _toolButtonKeys,
                    penGroupButtonKey: _penGroupButtonKey,
                    highlighterGroupButtonKey: _highlighterGroupButtonKey,
                    documentTitle: widget.documentTitle,
                    onHomePressed: widget.onHomePressed,
                    onRenameDocument: widget.onRenameDocument,
                    onDeleteDocument: widget.onDeleteDocument,
                    onSidebarToggle: _toggleSidebar,
                    isSidebarOpen: isSidebarOpen,
                    onToolPanelRequested: isCompactMode
                        ? (tool) => showToolPanelSheet(context: context, ref: ref, tool: tool)
                        : null,
                    onUndoPressed: _onUndoPressed,
                    onRedoPressed: _onRedoPressed,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // External left sidebar (e.g. AI chat) — tablet only
                        if (!isCompactMode && widget.externalLeftSidebar != null)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: widget.isExternalLeftSidebarOpen
                                ? widget.externalLeftSidebarWidth
                                : 0.0,
                            clipBehavior: Clip.hardEdge,
                            decoration: const BoxDecoration(),
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              maxWidth: widget.externalLeftSidebarWidth,
                              minWidth: widget.externalLeftSidebarWidth,
                              child: widget.externalLeftSidebar,
                            ),
                          ),
                        // Page sidebar — tablet only
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
                            pageTransitionKey: _pageTransitionKey,
                            onPageChanged: _navigateToPage,
                            colorScheme: ref.watch(canvasColorSchemeProvider),
                            isReadOnly: isReaderMode,
                            scrollDirection: ref.watch(scrollDirectionProvider),
                            isDualPage: ref.watch(dualPageModeProvider),
                            secondaryPage: ref.watch(secondaryPageProvider),
                            isCompactMode: isCompactMode,
                            nextPagePreviewColor: _getAdjacentPageColor(1),
                            prevPagePreviewColor: _getAdjacentPageColor(-1),
                            canSwipeForward: true,
                            canSwipeBack: ref.watch(canGoPreviousProvider),
                            onSwipeNavigate: _handleSwipeNavigate,
                            onDragDirectionDetermined: _onDragDirectionDetermined,
                            onDragReverted: _onDragReverted,
                            addPagePreview: ref.watch(currentPageIndexProvider) >=
                                ref.watch(pageCountProvider) - 1
                                ? _buildAddPagePreview() : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Phone external left sidebar overlay
              if (isCompactMode &&
                  widget.externalLeftSidebar != null &&
                  widget.isExternalLeftSidebarOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onExternalLeftSidebarClose,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: 0.5,
                      child: Container(color: Colors.black),
                    ),
                  ),
                ),
              // Phone external left sidebar drawer
              if (isCompactMode && widget.externalLeftSidebar != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: widget.isExternalLeftSidebarOpen
                      ? 0
                      : -widget.externalLeftSidebarWidth,
                  top: 0,
                  bottom: 0,
                  width: widget.externalLeftSidebarWidth,
                  child: Material(
                    elevation: 8,
                    child: widget.externalLeftSidebar!,
                  ),
                ),
              // Phone page sidebar overlay
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
              // Phone page sidebar drawer
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

  /// Builds a preview widget shown when swiping past the last page.
  /// Shows the page at its correct aspect ratio with surrounding area.
  Widget _buildAddPagePreview() {
    final bg = _resolveNewPageBackground();
    final cs = ref.read(canvasColorSchemeProvider);
    final canvasMode = widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    final pageSize = ref.read(documentProvider).settings.defaultPageSize;
    final surroundColor = canvasMode.isInfinite
        ? Color(bg.color) : Color(canvasMode.surroundingAreaColor);

    return LayoutBuilder(builder: (_, constraints) {
      final vw = constraints.maxWidth;
      final vh = constraints.maxHeight;
      final pw = pageSize.width;
      final ph = pageSize.height;
      // Fit page within viewport with padding
      final fitZoom = (vw / pw < vh / ph ? vw / pw : vh / ph) * 0.88;
      final pageW = pw * fitZoom;
      final pageH = ph * fitZoom;

      return Container(color: surroundColor, child: Stack(children: [
        // Centered page with correct aspect ratio
        Positioned(
          left: (vw - pageW) / 2, top: (vh - pageH) / 2,
          width: pageW, height: pageH,
          child: Container(
            decoration: BoxDecoration(
              color: Color(bg.color),
              border: Border.all(color: const Color(0x1A000000), width: 0.5),
              boxShadow: const [BoxShadow(
                color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: PageBackgroundView(
              background: bg, colorScheme: cs,
              pageSize: Size(pageW, pageH)),
          ),
        ),
        // Hint overlay
        Positioned.fill(child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 32),
            const SizedBox(height: 6),
            Text('Yeni sayfa eklemek için\nsürükleyip bırakın',
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceSerif4(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w500)),
          ]),
        ))),
      ]));
    });
  }

  /// Returns the background color of the page at offset from current.
  /// offset: 1 for next page, -1 for previous page.
  Color? _getAdjacentPageColor(int offset) {
    final pages = ref.read(pagesProvider);
    final currentIndex = ref.read(currentPageIndexProvider);
    final targetIndex = currentIndex + offset;
    if (targetIndex >= 0 && targetIndex < pages.length) {
      return Color(pages[targetIndex].background.color);
    }
    // For "add page after last", show same background as current page
    if (offset > 0) {
      return Color(pages[currentIndex].background.color);
    }
    return null;
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
