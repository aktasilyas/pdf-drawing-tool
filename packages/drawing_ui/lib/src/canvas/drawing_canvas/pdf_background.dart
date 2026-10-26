part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// PDF page background widgets (lazy load, placeholder, error).
mixin _PdfBackground on DrawingCanvasGestureHandlers<DrawingCanvas> {
  /// Build PDF background widget (with lazy loading + automatic prefetch).
  Widget _buildPdfBackground(core.Page page) {
    final background = page.background;

    // Eğer pdfData cache'de varsa direkt göster (immediate render)
    if (background.pdfData != null) {
      return Container(
        width: page.size.width,
        height: page.size.height,
        color: Colors.white,
        child: Image.memory(
          background.pdfData!,
          width: page.size.width,
          height: page.size.height,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true, // Smooth geçiş için
        ),
      );
    }

    // Lazy load - provider üzerinden render
    if (background.pdfFilePath != null && background.pdfPageIndex != null) {
      final cacheKey = '${background.pdfFilePath}|${background.pdfPageIndex}';

      return Consumer(
        builder: (context, ref, child) {
          // Mevcut zoom'u al
          final currentZoom = ref.watch(zoomBasedRenderProvider);
          final quality = getQualityForZoom(currentZoom);
          final qualityKey = getQualityCacheKey(cacheKey, quality);

          // Cache'e bak - önce kaliteli, yoksa normal
          final cache = ref.watch(pdfPageCacheProvider);
          final displayBytes = cache[qualityKey] ?? cache[cacheKey];

          if (displayBytes != null) {
            return Container(
              width: page.size.width,
              height: page.size.height,
              color: Colors.white,
              child: Image.memory(
                displayBytes,
                width: page.size.width,
                height: page.size.height,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                gaplessPlayback: true,
              ),
            );
          }

          // Cache'de yok - render provider'ı tetikle (standard quality)
          final renderAsync = ref.watch(pdfPageRenderProvider(cacheKey));

          return renderAsync.when(
            data: (bytes) {
              if (bytes != null) {
                return Container(
                  width: page.size.width,
                  height: page.size.height,
                  color: Colors.white,
                  child: Image.memory(
                    bytes,
                    width: page.size.width,
                    height: page.size.height,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    gaplessPlayback: true,
                  ),
                );
              }
              return _buildPdfPlaceholder(page);
            },
            loading: () => _buildPdfLoading(page),
            error: (e, st) => _buildPdfError(page, e.toString()),
          );
        },
      );
    }

    return _buildPdfPlaceholder(page);
  }

  /// PDF yükleniyor widget'ı (minimal - kullanıcıyı rahatsız etmez)
  Widget _buildPdfLoading(core.Page page) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: page.size.width,
      height: page.size.height,
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }

  /// PDF placeholder; shows a distinct state when the source PDF is missing.
  Widget _buildPdfPlaceholder(core.Page page) {
    return PdfPagePlaceholder(
      width: page.size.width,
      height: page.size.height,
      pdfFilePath: page.background.pdfFilePath,
    );
  }

  /// PDF hata widget'ı
  Widget _buildPdfError(core.Page page, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: page.size.width,
      height: page.size.height,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        // Gölge ekle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(ElyanotesIcons.warningCircle,
                  size: 40, color: colorScheme.error),
              const SizedBox(height: 8),
              Text(
                'PDF Yüklenemedi',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10, color: colorScheme.onErrorContainer),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
