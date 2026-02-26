/// Providers for drawing UI state management.
library;

export 'audio_recording_provider.dart';
export 'canvas_transform_provider.dart';
export 'document_provider.dart';
export 'drawing_providers.dart';
export 'eraser_provider.dart';
export 'eraser_settings_provider.dart';
export 'highlighter_settings_provider.dart';
export 'history_provider.dart';
export 'page_provider.dart';
export 'pdf_provider.dart';
export 'pen_settings_provider.dart';
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
export 'reader_mode_provider.dart';
export 'pen_picker_mode_provider.dart';
export 'sticker_provider.dart';
export 'image_provider.dart';
export 'sticky_note_provider.dart';
export 'page_trash_callback_provider.dart';
export 'scroll_direction_provider.dart';
export 'sidebar_filter_provider.dart';
export 'dual_page_provider.dart';
export 'zoom_lock_provider.dart';
export 'ruler_provider.dart';
export 'export_progress_provider.dart';
export 'copied_page_provider.dart';
export 'selection_clipboard_provider.dart';
export 'selection_actions_provider.dart';
export 'infinite_canvas_provider.dart';
