import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/drawing_screen.dart';
import 'package:drawing_ui/src/screens/drawing_screen_viewport.dart';
import 'package:drawing_ui/src/screens/page_sidebar.dart'
    show kPageSidebarWidth;
import 'package:drawing_ui/src/toolbar/toolbar_layout_mode.dart';

/// Sidebar toggling and canvas viewport/transform upkeep for
/// [DrawingScreen]'s state.
mixin DrawingScreenViewportSync on ConsumerState<DrawingScreen> {
  bool get isSidebarOpen => ref.read(sidebarOpenProvider);

  void toggleSidebar() {
    ref.read(sidebarOpenProvider.notifier).state = !isSidebarOpen;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) recalculateCanvasTransform();
    });
  }

  void closeSidebar() {
    ref.read(sidebarOpenProvider.notifier).state = false;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) recalculateCanvasTransform();
    });
  }

  void recalculateCanvasTransform() {
    final size = MediaQuery.of(context).size;
    final viewportSize = computeCanvasViewport(
      screenSize: size,
      isTablet: size.width >= ToolbarLayoutMode.compactBreakpoint,
      isPageSidebarOpen: isSidebarOpen,
      pageCount: ref.read(pageCountProvider),
      pageSidebarWidth: kPageSidebarWidth,
      isExternalSidebarOpen: widget.isExternalLeftSidebarOpen,
      externalSidebarWidth: widget.externalLeftSidebarWidth,
      currentCanvasHeight: ref.read(canvasViewportSizeProvider).height,
    );
    ref.read(canvasViewportSizeProvider.notifier).state = viewportSize;
    final currentPage = ref.read(currentPageProvider);
    final pageSize = Size(currentPage.size.width, currentPage.size.height);
    final canvasMode =
        widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (!canvasMode.isInfinite) {
      ref.read(canvasTransformProvider.notifier).recenterForViewport(
            viewportSize: viewportSize,
            pageSize: pageSize,
          );
    }
  }

  void handleDocumentPageChange(core.DrawingDocument current) {
    final hasPdfPages = current.pages.any((p) =>
        p.background.type == core.BackgroundType.pdf &&
        p.background.pdfFilePath != null);
    if (hasPdfPages) {
      ref.read(pdfPrefetchManagerProvider).prefetchAround(
            currentPageIndex: current.currentPageIndex,
            allPages: current.pages,
          );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) recalculateCanvasTransform();
    });
  }

  /// Registers the page-index and document listeners; call from `build`.
  void listenToDocumentChanges() {
    // Sync page index from PageManager → DocumentProvider.
    // This ensures all navigation sources (indicator bar, swipe, sidebar)
    // keep the document's currentPageIndex in sync for correct auto-save.
    ref.listen<int>(currentPageIndexProvider, (previous, current) {
      if (previous != null && previous != current) {
        final doc = ref.read(documentProvider);
        if (doc.isMultiPage && doc.currentPageIndex != current) {
          ref
              .read(documentProvider.notifier)
              .updateDocument(doc.setCurrentPage(current));
        }
      }
    });

    // Listen to document changes for PDF prefetch and canvas transform
    ref.listen<core.DrawingDocument>(documentProvider, (previous, current) {
      if (previous != null &&
          previous.currentPageIndex != current.currentPageIndex) {
        handleDocumentPageChange(current);
      }
    });
  }
}
