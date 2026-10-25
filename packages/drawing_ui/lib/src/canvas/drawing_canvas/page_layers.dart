part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Page shadow, PDF background and page fill of limited-mode canvases.
mixin _CanvasPageLayers
    on DrawingCanvasGestureHandlers<DrawingCanvas>, _PdfBackground {
  List<Widget> _buildPageLayers(_CanvasFrame f) {
    final canvasMode = f.canvasMode;
    final currentPage = f.currentPage;
    final colorScheme = f.colorScheme;
    return [
      // Sayfa gölgesi - PDF için KAPALI
      if (canvasMode.showPageShadow &&
          currentPage.background.type != BackgroundType.pdf)
        Positioned(
          left: 0,
          top: 0,
          child: IgnorePointer(
            child: Container(
              width: currentPage.size.width,
              height: currentPage.size.height,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),

      // PDF BACKGROUND - Lazy Loading destekli
      if (currentPage.background.type == BackgroundType.pdf) ...[
        Positioned(
          left: 0,
          top: 0,
          child: IgnorePointer(
            child: _buildPdfBackground(currentPage),
          ),
        ),
      ],

      // Sayfa arka planı + pattern (PDF DEĞİLSE göster)
      if (currentPage.background.type != BackgroundType.pdf)
        Positioned(
          left: 0,
          top: 0,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: ClipRect(
                child: Container(
                  width: currentPage.size.width,
                  height: currentPage.size.height,
                  decoration: BoxDecoration(
                    color: colorScheme
                        .effectiveBackground(currentPage.background.color),
                    border: canvasMode.pageBorderWidth > 0
                        ? Border.all(
                            color: Color(canvasMode.pageBorderColor),
                            width: canvasMode.pageBorderWidth,
                          )
                        : null,
                  ),
                  child: PageBackgroundView(
                    background: currentPage.background,
                    colorScheme: colorScheme,
                    pageSize:
                        Size(currentPage.size.width, currentPage.size.height),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }
}
