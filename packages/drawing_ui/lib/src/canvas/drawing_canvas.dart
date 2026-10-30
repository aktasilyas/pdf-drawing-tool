import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_core/drawing_core.dart' show BackgroundType;
import 'package:drawing_ui/src/canvas/active_stroke_layer.dart';
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/passive_layer_painter.dart';
import 'package:drawing_ui/src/canvas/selection_painter.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/active_layer_content.dart';
import 'package:drawing_ui/src/canvas/sticky_note_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_handles_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_resize_handles.dart';
import 'package:drawing_ui/src/canvas/selected_elements_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_view.dart';
import 'package:drawing_ui/src/canvas/pdf_page_placeholder.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';
import 'package:drawing_ui/src/canvas/editor_memory_pressure_observer.dart';
import 'package:drawing_ui/src/canvas/laser_controller.dart';
import 'package:drawing_ui/src/canvas/laser_overlay_widget.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';
import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/eraser_provider.dart';
import 'package:drawing_ui/src/providers/tool_style_provider.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';
import 'package:drawing_ui/src/providers/shape_provider.dart';
import 'package:drawing_ui/src/providers/text_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart'
    show clearPdfCacheProvider;
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/providers/canvas_dark_mode_provider.dart';
import 'package:drawing_ui/src/providers/sticker_provider.dart';
import 'package:drawing_ui/src/providers/image_provider.dart';
import 'package:drawing_ui/src/providers/sticky_note_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/infinite_canvas_provider.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';

part 'drawing_canvas/canvas_fields.dart';
part 'drawing_canvas/gesture_contract.dart';
part 'drawing_canvas/page_init.dart';
part 'drawing_canvas/pdf_background.dart';
part 'drawing_canvas/canvas_frame.dart';
part 'drawing_canvas/canvas_frame_reader.dart';
part 'drawing_canvas/ink_layers.dart';
part 'drawing_canvas/page_layers.dart';
part 'drawing_canvas/selection_layers.dart';
part 'drawing_canvas/canvas_viewport.dart';
part 'drawing_canvas/sticky_note_menu.dart';
part 'drawing_canvas/placement_indicators.dart';
part 'drawing_canvas/canvas_overlays.dart';

// =============================================================================
// DRAWING CANVAS WIDGET
// =============================================================================

/// The main drawing canvas widget that handles stroke rendering.
///
/// This widget uses a multi-layer architecture for optimal performance:
/// - Layer 1: Background grid (never repaints)
/// - Layer 2: Committed strokes (repaints only when strokes are added/removed)
/// - Layer 6: Selection handles (for drag interactions)
///
/// ## Performance Rules Applied:
/// - NO setState for drawing updates
/// - RepaintBoundary isolates each layer
/// - Cached renderer instance
/// - Optimized shouldRepaint in all painters
///
/// ## Usage
/// ```dart
/// DrawingCanvas(
///   width: 800,
///   height: 600,
/// )
/// ```
class DrawingCanvas extends ConsumerStatefulWidget {
  /// Width of the canvas. Defaults to fill available space.
  final double width;

  /// Height of the canvas. Defaults to fill available space.
  final double height;

  /// Canvas mode configuration (determines behavior)
  final core.CanvasMode? canvasMode;

  /// When true, drawing gestures are disabled but pan/zoom remains active.
  final bool isReadOnly;

  /// Callback for two-finger swipe page navigation.
  /// Receives +1 (next page) or -1 (previous page).
  final ValueChanged<int>? onPageSwipe;

  /// Interactive two-finger swipe drag callbacks for smooth page transitions.
  final VoidCallback? onPageSwipeDragBegin;
  final ValueChanged<double>? onPageSwipeDragUpdate;
  final ValueChanged<double>? onPageSwipeDragEnd;

  const DrawingCanvas({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.canvasMode,
    this.isReadOnly = false,
    this.onPageSwipe,
    this.onPageSwipeDragBegin,
    this.onPageSwipeDragUpdate,
    this.onPageSwipeDragEnd,
  });

  @override
  ConsumerState<DrawingCanvas> createState() => DrawingCanvasState();
}

/// State for [DrawingCanvas].
///
/// Exposed as public for testing purposes.
/// Uses mixins for gesture handling and helpers to keep file size manageable.
class DrawingCanvasState extends DrawingCanvasGestureHandlers<DrawingCanvas>
    with
        _CanvasFields,
        _GestureContract,
        _CanvasPageInit,
        _PdfBackground,
        _CanvasFrameReader,
        _CanvasInkLayers,
        _CanvasPageLayers,
        _CanvasSelectionLayers,
        _CanvasViewport,
        _StickyNoteMenu,
        _PlacementIndicators,
        _CanvasOverlays {
  /// Exposes the image cache for testing.
  @visibleForTesting
  ImageCacheManager get debugImageCacheManager => _imageCacheManager;

  /// Exposes committed strokes from provider for testing.
  @visibleForTesting
  List<core.Stroke> get committedStrokes =>
      ref.read(activeLayerStrokesProvider);

  @override
  void initState() {
    super.initState();
    _drawingController = DrawingController();
    _laserController = LaserController();
    _memoryPressure = EditorMemoryPressureObserver(_onMemoryPressure);
  }

  late final EditorMemoryPressureObserver _memoryPressure;

  /// Low memory: drop the PDF byte caches and images not painted lately.
  void _onMemoryPressure() {
    ref.read(clearPdfCacheProvider)();
    _imageCacheManager.trim();
  }

  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Canvas mode değiştiyse (farklı döküman türü) initialization'ı resetle
    if (oldWidget.canvasMode != widget.canvasMode) {
      _hasInitialized = false;
      _lastViewportSize = null;
      _lastPageSize = null;
    }
  }

  @override
  void dispose() {
    _memoryPressure.dispose();
    _drawingController.dispose();
    _laserController.dispose();
    _imageCacheManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _readFrame();
    final transform = f.transform;
    final canvasMode = f.canvasMode;
    final currentPage = f.currentPage;

    // Listen to page changes - reset initialization and trigger prefetch
    ref.listen<core.Page>(currentPageProvider, (previous, current) {
      if (previous != null && previous.id != current.id) {
        _hasInitialized = false;
        finishTextEditingOnPageChange();

        // 🚀 PDF sayfaları için adjacent prefetch tetikle
        if (current.background.type == BackgroundType.pdf &&
            current.background.pdfFilePath != null &&
            current.background.pdfPageIndex != null) {
          // pdfPageIndex kullan (1-based), document page index değil
          prefetchOnPageChange(ref, current.background.pdfPageIndex!);
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          widget.width == double.infinity ? constraints.maxWidth : widget.width,
          widget.height == double.infinity
              ? constraints.maxHeight
              : widget.height,
        );

        // Initialize canvas for limited mode (centers page on first render)
        if (!canvasMode.isInfinite) {
          _initializeCanvasForLimitedMode(size, currentPage);
        }

        final effectiveTransform =
            _effectiveTransform(transform, canvasMode, currentPage, size);

        // Wrap everything in a Stack to put menu/overlay OUTSIDE gesture handlers
        return Stack(
          children: [
            // ═══════════════════════════════════════════════════════════════════
            // LAYER -1: Surrounding Area Background (OUTSIDE Transform)
            // ═══════════════════════════════════════════════════════════════════
            // This fills the entire viewport with surrounding color.
            // Being OUTSIDE Transform means it doesn't move with zoom/pan.
            if (!canvasMode.isInfinite)
              Positioned.fill(
                child: ColoredBox(
                  color: Color(canvasMode.surroundingAreaColor),
                ),
              ),

            _buildViewport(f, size, effectiveTransform),

            ..._buildScreenOverlays(f),
          ],
        );
      },
    );
  }
}
