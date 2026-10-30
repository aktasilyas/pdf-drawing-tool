import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/toolbar/toolbar.dart';
import 'package:drawing_ui/src/screens/canvas_brightness_sync.dart';
import 'package:drawing_ui/src/screens/drawing_screen_layout.dart';
import 'package:drawing_ui/src/screens/drawing_screen_theme.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';

import 'package:drawing_ui/src/screens/drawing_screen_add_page_preview.dart';
import 'package:drawing_ui/src/screens/drawing_screen_navigation.dart';
import 'package:drawing_ui/src/screens/drawing_screen_sidebars.dart';
import 'package:drawing_ui/src/screens/drawing_screen_toolbar_actions.dart';
import 'package:drawing_ui/src/screens/drawing_screen_viewport_sync.dart';
import 'package:drawing_ui/src/services/new_page_size.dart';

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
    this.thumbnailCache,
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

  /// Thumbnail cache for the page sidebar; tests pass a pre-filled one so
  /// goldens show pages instead of loading spinners.
  final ThumbnailCache? thumbnailCache;

  @override
  ConsumerState<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends ConsumerState<DrawingScreen>
    with
        DrawingScreenNavigation,
        DrawingScreenViewportSync,
        DrawingScreenToolbarActions {
  final Map<ToolType, GlobalKey> _toolButtonKeys = {
    for (final tool in ToolType.values) tool: GlobalKey()
  };
  final GlobalKey _penGroupButtonKey = GlobalKey();
  final GlobalKey _highlighterGroupButtonKey = GlobalKey();
  final GlobalKey _settingsButtonKey = GlobalKey();
  final PopoverController _panelController = PopoverController();
  late final ThumbnailCache _thumbnailCache =
      widget.thumbnailCache ?? ThumbnailCache(maxSize: 20);
  Offset _penBoxPosition = const Offset(12, 12);
  VoidCallback? _unregisterDrawerBack;

  @override
  void didUpdateWidget(DrawingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExternalLeftSidebarOpen !=
        widget.isExternalLeftSidebarOpen) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) recalculateCanvasTransform();
      });
    }
  }

  @override
  void dispose() {
    _unregisterDrawerBack?.call();
    _panelController.dispose();
    _thumbnailCache.clear();
    super.dispose();
  }

  /// Lets system Back close the phone drawer before the notebook (#482).
  void _syncDrawerBack(bool drawerOpen) {
    if (!drawerOpen) {
      _unregisterDrawerBack?.call();
      _unregisterDrawerBack = null;
    } else if (_unregisterDrawerBack == null) {
      _unregisterDrawerBack =
          DismissibleOverlays.instance.register(_closeOpenDrawer);
    }
  }

  void _closeOpenDrawer() {
    _unregisterDrawerBack = null;
    if (!mounted) return;
    if (widget.externalLeftSidebar != null &&
        widget.isExternalLeftSidebarOpen) {
      widget.onExternalLeftSidebarClose?.call();
    } else {
      closeSidebar();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to activePanel changes
    ref.listen<ToolType?>(activePanelProvider, (previous, next) {
      handlePanelChange(
        context: context,
        panel: next,
        panelController: _panelController,
        toolButtonKeys: _toolButtonKeys,
        penGroupButtonKey: _penGroupButtonKey,
        highlighterGroupButtonKey: _highlighterGroupButtonKey,
        settingsButtonKey: _settingsButtonKey,
        onClosePanel: closePanel,
      );
    });

    listenToDocumentChanges();
    // Keeps the thumbnails' PDF documents open while the editor is open.
    ref.watch(pdfThumbnailDocumentsProvider);

    final isReaderMode = ref.watch(readerModeProvider);
    final currentPage = ref.watch(currentPageProvider);
    final transform = ref.watch(canvasTransformProvider);
    final canvasMode =
        widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    // Defer provider modification to after build completes
    final isInfinite = canvasMode.isInfinite;
    final aiEnabled = ref.watch(aiAssistantEnabledProvider);
    final aiCallback =
        !aiEnabled ? null : (widget.onAIPressed ?? () => openAIPanel(context));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(isInfiniteCanvasProvider.notifier).state = isInfinite;
        ref.read(onAIPressedCallbackProvider.notifier).state = aiCallback;
      }
    });
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactMode = screenWidth < ToolbarLayoutMode.compactBreakpoint;
    final isSidebarOpen = ref.watch(sidebarOpenProvider);
    final showSidebar = isSidebarOpen && ref.watch(pageCountProvider) > 1;
    _syncDrawerBack(
      isCompactMode &&
          (showSidebar ||
              (widget.externalLeftSidebar != null &&
                  widget.isExternalLeftSidebarOpen)),
    );

    final scaffoldBgColor = canvasMode.isInfinite
        ? Color(currentPage.background.color)
        : Color(canvasMode.surroundingAreaColor);

    final drawingTheme = drawingThemeFromChrome(ChromePalette.of(context));

    final screen = DrawingThemeProvider(
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
                    onAIPressed: aiCallback,
                    onSettingsPressed: onSettingsPressed,
                    settingsButtonKey: _settingsButtonKey,
                    toolButtonKeys: _toolButtonKeys,
                    penGroupButtonKey: _penGroupButtonKey,
                    highlighterGroupButtonKey: _highlighterGroupButtonKey,
                    documentTitle: widget.documentTitle,
                    onHomePressed: widget.onHomePressed,
                    onRenameDocument: widget.onRenameDocument,
                    onDeleteDocument: widget.onDeleteDocument,
                    onSidebarToggle: toggleSidebar,
                    isSidebarOpen: isSidebarOpen,
                    onToolPanelRequested: isCompactMode
                        ? (tool) => showToolPanelSheet(
                            context: context, ref: ref, tool: tool)
                        : null,
                    onUndoPressed: onUndoPressed,
                    onRedoPressed: onRedoPressed,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        if (!isCompactMode)
                          ...buildTabletSidePanels(
                            externalLeftSidebar: widget.externalLeftSidebar,
                            isExternalLeftSidebarOpen:
                                widget.isExternalLeftSidebarOpen,
                            externalLeftSidebarWidth:
                                widget.externalLeftSidebarWidth,
                            showPageSidebar: showSidebar,
                            thumbnailCache: _thumbnailCache,
                            onPageTap: navigateToPage,
                          ),
                        Expanded(
                          child: buildDrawingCanvasArea(
                            context: context,
                            ref: ref,
                            currentPage: currentPage,
                            transform: transform,
                            canvasMode: widget.canvasMode,
                            penBoxPosition: _penBoxPosition,
                            onPenBoxPositionChanged: (p) =>
                                setState(() => _penBoxPosition = p),
                            onClosePanel: closePanel,
                            pageTransitionKey: pageTransitionKey,
                            onPageChanged: navigateToPage,
                            colorScheme: ref.watch(canvasColorSchemeProvider),
                            isReadOnly: isReaderMode,
                            scrollDirection: ref.watch(scrollDirectionProvider),
                            isDualPage: ref.watch(dualPageModeProvider),
                            secondaryPage: ref.watch(secondaryPageProvider),
                            isCompactMode: isCompactMode,
                            nextPagePreviewColor: adjacentPageColor(1),
                            prevPagePreviewColor: adjacentPageColor(-1),
                            canSwipeForward: true,
                            canSwipeBack: ref.watch(canGoPreviousProvider),
                            onSwipeNavigate: handleSwipeNavigate,
                            onDragDirectionDetermined:
                                onDragDirectionDetermined,
                            onDragReverted: onDragReverted,
                            addPagePreview:
                                ref.watch(currentPageIndexProvider) >=
                                        ref.watch(pageCountProvider) - 1
                                    ? _buildAddPagePreview()
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isCompactMode)
                ...buildPhoneDrawers(
                  externalLeftSidebar: widget.externalLeftSidebar,
                  isExternalLeftSidebarOpen: widget.isExternalLeftSidebarOpen,
                  externalLeftSidebarWidth: widget.externalLeftSidebarWidth,
                  onExternalLeftSidebarClose: widget.onExternalLeftSidebarClose,
                  showPageSidebar: showSidebar,
                  screenWidth: screenWidth,
                  onClosePageSidebar: closeSidebar,
                  thumbnailCache: _thumbnailCache,
                  onPageTap: navigateToPage,
                ),
            ],
          ),
        ),
      ),
    );
    return CanvasBrightnessSync(child: screen);
  }

  Widget _buildAddPagePreview() {
    return AddPagePreview(
      background: resolveNewPageBackground(),
      colorScheme: ref.read(canvasColorSchemeProvider),
      canvasMode: widget.canvasMode ?? const core.CanvasMode(isInfinite: true),
      pageSize: resolveNewPageSize(
        ref.read(documentProvider),
        ref.read(currentPageIndexProvider),
      ),
    );
  }
}
