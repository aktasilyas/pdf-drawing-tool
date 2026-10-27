import 'dart:ui' show Size;

/// Breakpoint-independent math for the canvas viewport of the drawing screen.
///
/// On tablets the page sidebar and the external left sidebar sit beside the
/// canvas and shrink it; on phones they are overlays and take no space.
Size computeCanvasViewport({
  required Size screenSize,
  required bool isTablet,
  required bool isPageSidebarOpen,
  required int pageCount,
  required double pageSidebarWidth,
  required bool isExternalSidebarOpen,
  required double externalSidebarWidth,
  required double currentCanvasHeight,
}) {
  final showSidebar = isPageSidebarOpen && pageCount > 1;
  final sidebarWidth = (isTablet && showSidebar) ? pageSidebarWidth : 0.0;
  final externalInset =
      (isTablet && isExternalSidebarOpen) ? externalSidebarWidth : 0.0;
  // Use the measured canvas height (LayoutBuilder), not the full screen height.
  final height =
      currentCanvasHeight > 0 ? currentCanvasHeight : screenSize.height;
  return Size(screenSize.width - sidebarWidth - externalInset, height);
}
