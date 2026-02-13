/// Providers for drawing UI state management.
library;

export 'canvas_transform_provider.dart';
export 'document_provider.dart';
export 'drawing_providers.dart';
export 'eraser_provider.dart';
export 'history_provider.dart';
export 'page_provider.dart';
export 'pdf_provider.dart';
export 'recent_colors_provider.dart';
export 'selection_provider.dart';
export 'shape_provider.dart';
export 'text_provider.dart';
export 'toolbar_config_provider.dart';
export 'tool_style_provider.dart';

// PDF render providers
export 'pdf_render_provider.dart'
    show
        pdfPageCacheProvider,
        pdfThumbnailCacheProvider,
        renderThumbnail,
        pdfPageRenderProvider,
        pdfBulkPrefetchProvider,
        BulkPrefetchRequest,
        prefetchOnPageChange,
        visiblePdfPageProvider,
        currentPdfFilePathProvider,
        totalPdfPagesProvider,
        clearPdfCacheProvider,
        pdfCacheSizeProvider,
        pdfCacheSizeMBProvider,
        pdfCacheCountProvider,
        pdfRenderQueueProvider;

export 'pdf_prefetch_provider.dart';
export 'canvas_dark_mode_provider.dart';
