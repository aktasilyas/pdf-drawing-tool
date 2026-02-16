import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_core/drawing_core.dart' show BackgroundType;
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/selection_painter.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:drawing_ui/src/canvas/text_painter.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/image_resize_handles.dart';
import 'package:drawing_ui/src/canvas/selected_elements_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_helpers.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';
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
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/providers/canvas_dark_mode_provider.dart';
import 'package:drawing_ui/src/providers/sticker_provider.dart';
import 'package:drawing_ui/src/providers/image_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';

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

  const DrawingCanvas({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.canvasMode,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<DrawingCanvas> createState() => DrawingCanvasState();
}

/// State for [DrawingCanvas].
///
/// Exposed as public for testing purposes.
/// Uses mixins for gesture handling and helpers to keep file size manageable.
class DrawingCanvasState extends ConsumerState<DrawingCanvas>
    with DrawingCanvasHelpers, DrawingCanvasGestureHandlers {
  /// Canvas mode configuration (for gesture handlers)
  @override
  core.CanvasMode? get canvasMode => widget.canvasMode;

  /// Controller for managing active stroke state.
  /// Uses ChangeNotifier instead of setState for performance.
  late final DrawingController _drawingController;

  /// Cached renderer instance - shared across all painters.
  final FlutterStrokeRenderer _renderer = FlutterStrokeRenderer();

  // ─────────────────────────────────────────────────────────────────────────
  // GESTURE HANDLING - Performance optimizations
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum distance between points to avoid excessive point creation.
  /// Points closer than this are skipped for performance.

  /// Last recorded point position for distance filtering.
  Offset? _lastPoint;

  // ─────────────────────────────────────────────────────────────────────────
  // ZOOM/PAN GESTURE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Number of active pointers (fingers) on the canvas.
  /// Used to distinguish between drawing (1 finger) and zoom/pan (2 fingers).
  int _pointerCount = 0;

  /// Last focal point for scale gesture (zoom/pan center point).
  Offset? _lastFocalPoint;

  /// Last scale value for calculating zoom delta.
  double? _lastScale;

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether a selection operation is in progress.
  bool _isSelecting = false;

  // ─────────────────────────────────────────────────────────────────────────
  // SHAPE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether a shape drawing operation is in progress.
  bool _isDrawingShape = false;

  /// Active shape tool instance.
  core.ShapeTool? _activeShapeTool;

  // ─────────────────────────────────────────────────────────────────────────
  // STRAIGHT LINE MODE TRACKING (for highlighters)
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether straight line drawing is in progress.
  bool _isStraightLineDrawing = false;

  /// Start point for straight line.
  core.DrawingPoint? _straightLineStart;

  /// Current end point for straight line (for preview).
  core.DrawingPoint? _straightLineEnd;

  /// Style for straight line.
  core.StrokeStyle? _straightLineStyle;

  // ─────────────────────────────────────────────────────────────────────────
  // ERASER SHAPE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Shape IDs erased in current gesture session.
  final Set<String> _erasedShapeIds = {};

  /// Text IDs erased in current gesture session.
  final Set<String> _erasedTextIds = {};

  /// Image IDs erased in current gesture session.
  final Set<String> _erasedImageIds = {};

  // ─────────────────────────────────────────────────────────────────────────
  // PIXEL ERASER TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Accumulated segment hits for pixel eraser during a gesture.
  final Map<String, List<int>> _pixelEraseHits = {};

  /// Original strokes affected by pixel eraser (for undo).
  final List<core.Stroke> _pixelEraseOriginalStrokes = [];

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Image cache manager for decoded ui.Image objects.
  final ImageCacheManager _imageCacheManager = ImageCacheManager();

  /// Whether canvas has been initialized for limited mode.
  bool _hasInitialized = false;

  /// Last viewport size for detecting orientation changes.
  Size? _lastViewportSize;

  // ─────────────────────────────────────────────────────────────────────────
  // Public Getters/Setters (for mixins and testing)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  @visibleForTesting
  DrawingController get drawingController => _drawingController;

  /// Exposes committed strokes from provider for testing.
  @visibleForTesting
  List<core.Stroke> get committedStrokes =>
      ref.read(activeLayerStrokesProvider);

  @override
  void initState() {
    super.initState();
    _drawingController = DrawingController();
  }

  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Canvas mode değiştiyse (farklı döküman türü) initialization'ı resetle
    if (oldWidget.canvasMode != widget.canvasMode) {
      _hasInitialized = false;
      _lastViewportSize = null;
    }
  }

  @override
  void dispose() {
    _drawingController.dispose();
    _imageCacheManager.dispose();
    super.dispose();
  }

  void _handleSelectionDelete(core.Selection selection) {
    final document = ref.read(documentProvider);
    final command = core.DeleteSelectionCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: selection.selectedStrokeIds,
      shapeIds: selection.selectedShapeIds,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(selectionProvider.notifier).clearSelection();
    ref.read(selectionUiProvider.notifier).reset();
  }

  void _handleSelectionDuplicate(core.Selection selection) {
    final document = ref.read(documentProvider);
    final command = core.DuplicateSelectionCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: selection.selectedStrokeIds,
      shapeIds: selection.selectedShapeIds,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(selectionUiProvider.notifier).reset();
    ref.read(selectionProvider.notifier).clearSelection();
  }

  void _handleSelectionColorChange(core.Selection selection, Color color) {
    if (selection.selectedStrokeIds.isEmpty) return;
    final document = ref.read(documentProvider);
    final command = core.ChangeSelectionStyleCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: selection.selectedStrokeIds,
      newColor: color.toARGB32(),
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(selectionUiProvider.notifier).hideContextMenu();
  }

  Widget _imageMenuButton(
      PhosphorIconData icon, String tooltip, VoidCallback onTap, Color? color) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: PhosphorIcon(icon, size: 20, color: color ?? Colors.black87),
        ),
      ),
    );
  }

  Widget _imageMenuDivider() {
    return Container(width: 1, height: 24, color: Colors.grey[300]);
  }

  /// Initialize canvas transform for limited mode (page centering).
  void _initializeCanvasForLimitedMode(
      Size viewportSize, core.Page currentPage) {
    final canvasMode =
        widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (canvasMode.isInfinite) {
      _hasInitialized = true;
      _lastViewportSize = viewportSize;
      return;
    }

    // Check if viewport size changed significantly (orientation change)
    final needsReInit = !_hasInitialized || _isOrientationChanged(viewportSize);
    if (!needsReInit) return;

    // Mark as initialized immediately to prevent multiple calls
    _hasInitialized = true;
    _lastViewportSize = viewportSize;

    // CRITICAL FIX: Initialize immediately on first build (not in postFrameCallback)
    // This prevents the "small square" bug on initial render
    final currentTransform = ref.read(canvasTransformProvider);
    final isDefaultTransform =
        currentTransform.zoom == 1.0 && currentTransform.offset == Offset.zero;

      // Schedule initialization (immediate callback)
    if (isDefaultTransform) {
      // First time - use immediate callback (before next frame)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(canvasTransformProvider.notifier).initializeForPage(
              viewportSize: viewportSize,
              pageSize: Size(currentPage.size.width, currentPage.size.height),
            );
      });
    } else {
      // Re-initialization (orientation change)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(canvasTransformProvider.notifier).initializeForPage(
              viewportSize: viewportSize,
              pageSize: Size(currentPage.size.width, currentPage.size.height),
            );
      });
    }
  }

  /// Check if orientation changed (width/height swapped).
  bool _isOrientationChanged(Size newSize) {
    final lastSize = _lastViewportSize;
    if (lastSize == null) return false;

    final wasPortrait = lastSize.height > lastSize.width;
    final isPortrait = newSize.height > newSize.width;

    return wasPortrait != isPortrait;
  }

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

  /// PDF placeholder widget'ı
  Widget _buildPdfPlaceholder(core.Page page) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: page.size.width,
      height: page.size.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(StarNoteIcons.pdfFile, size: 40, color: colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text(
              'PDF Sayfası',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
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
              PhosphorIcon(StarNoteIcons.warningCircle, size: 40, color: colorScheme.error),
              const SizedBox(height: 8),
              Text(
                'PDF Yüklenemedi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onErrorContainer),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                style: TextStyle(fontSize: 10, color: colorScheme.onErrorContainer),
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

  /// Trigger high-quality render when user zooms in
  @override
  int get pointerCount => _pointerCount;
  @override
  set pointerCount(int value) => _pointerCount = value;

  @override
  Offset? get lastPoint => _lastPoint;
  @override
  set lastPoint(Offset? value) => _lastPoint = value;

  @override
  bool get isSelecting => _isSelecting;
  @override
  set isSelecting(bool value) => _isSelecting = value;

  @override
  bool get isDrawingShape => _isDrawingShape;
  @override
  set isDrawingShape(bool value) => _isDrawingShape = value;

  @override
  core.ShapeTool? get activeShapeTool => _activeShapeTool;
  @override
  set activeShapeTool(core.ShapeTool? value) => _activeShapeTool = value;

  @override
  bool get isStraightLineDrawing => _isStraightLineDrawing;
  @override
  set isStraightLineDrawing(bool value) => _isStraightLineDrawing = value;

  @override
  core.DrawingPoint? get straightLineStart => _straightLineStart;
  @override
  set straightLineStart(core.DrawingPoint? value) => _straightLineStart = value;

  @override
  core.DrawingPoint? get straightLineEnd => _straightLineEnd;
  @override
  set straightLineEnd(core.DrawingPoint? value) => _straightLineEnd = value;

  @override
  core.StrokeStyle? get straightLineStyle => _straightLineStyle;
  @override
  set straightLineStyle(core.StrokeStyle? value) => _straightLineStyle = value;

  @override
  Set<String> get erasedShapeIds => _erasedShapeIds;

  @override
  Set<String> get erasedTextIds => _erasedTextIds;

  @override
  Set<String> get erasedImageIds => _erasedImageIds;

  @override
  Map<String, List<int>> get pixelEraseHits => _pixelEraseHits;

  @override
  List<core.Stroke> get pixelEraseOriginalStrokes => _pixelEraseOriginalStrokes;

  @override
  Offset? get lastFocalPoint => _lastFocalPoint;
  @override
  set lastFocalPoint(Offset? value) => _lastFocalPoint = value;

  @override
  double? get lastScale => _lastScale;
  @override
  set lastScale(double? value) => _lastScale = value;

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final strokes = ref.watch(activeLayerStrokesProvider);
    final shapes = ref.watch(activeLayerShapesProvider);
    final texts = ref.watch(activeLayerTextsProvider);
    final isDrawingTool = ref.watch(isDrawingToolProvider);
    final isSelectionTool = ref.watch(isSelectionToolProvider);
    final isShapeTool = ref.watch(isShapeToolProvider);
    final currentTool = ref.watch(currentToolProvider);
    final transform = ref.watch(canvasTransformProvider);
    final selection = ref.watch(selectionProvider);
    final selectionUi = ref.watch(selectionUiProvider);
    final textToolState = ref.watch(textToolProvider);

    // Canvas mode configuration
    final canvasMode =
        widget.canvasMode ?? const core.CanvasMode(isInfinite: true);

    // Current page (LIMITED mod için)
    final currentPage = ref.watch(currentPageProvider);
    final colorScheme = ref.watch(canvasColorSchemeProvider);

    // Listen to page changes - reset initialization and trigger prefetch
    ref.listen<core.Page>(currentPageProvider, (previous, current) {
      if (previous != null && previous.id != current.id) {
        _hasInitialized = false;

        // 🚀 PDF sayfaları için adjacent prefetch tetikle
        if (current.background.type == BackgroundType.pdf &&
            current.background.pdfFilePath != null) {
          // Yeni prefetch sistemi - otomatik adjacent sayfaları yükler
          prefetchOnPageChange(ref, current.index);
        }
      }
    });

    // Eraser cursor state
    final eraserCursorPosition = ref.watch(eraserCursorPositionProvider);
    final lassoEraserPoints = ref.watch(lassoEraserPointsProvider);
    final isEraserTool = ref.watch(isEraserToolProvider);
    final pixelEraserPreview = ref.watch(pixelEraserPreviewProvider);

    // Selection tool preview path
    List<core.DrawingPoint>? selectionPreviewPath;
    if (isSelectionTool && _isSelecting) {
      selectionPreviewPath = ref.read(activeSelectionToolProvider).currentPath;
    }

    // Compute excluded IDs + selected elements for live transform
    final hasLiveTransform = selectionUi.hasTransform;
    Set<String> excludedStrokeIds = const {};
    Set<String> excludedShapeIds = const {};
    List<core.Stroke> selectedStrokes = const [];
    List<core.Shape> selectedShapes = const [];

    if (selection != null && hasLiveTransform) {
      excludedStrokeIds = selection.selectedStrokeIds.toSet();
      excludedShapeIds = selection.selectedShapeIds.toSet();

      selectedStrokes = strokes
          .where((s) => excludedStrokeIds.contains(s.id))
          .toList();
      selectedShapes = shapes
          .where((s) => excludedShapeIds.contains(s.id))
          .toList();
    }

    // Shape preview
    core.Shape? previewShape;
    if (_isDrawingShape && _activeShapeTool != null) {
      previewShape = _activeShapeTool!.previewShape;
    }

    // Straight line preview (for highlighter)
    List<core.DrawingPoint>? straightLinePreviewPoints;
    core.StrokeStyle? straightLinePreviewStyle;
    final start = _straightLineStart;
    final end = _straightLineEnd;
    if (_isStraightLineDrawing && start != null && end != null) {
      straightLinePreviewPoints = [start, end];
      straightLinePreviewStyle = _straightLineStyle;
    }

    // Watch images for active layer
    final images = ref.watch(activeLayerImagesProvider);

    // Enable pointer events for drawing tools, selection tool, shape tool, text tool,
    // sticker placement mode, image tool, and image placement mode.
    // In read-only mode, all drawing pointer events are disabled (pan/zoom still works)
    final isTextTool = currentTool == ToolType.text;
    final isStickerTool = currentTool == ToolType.sticker;
    final isImageTool = currentTool == ToolType.image;
    final isStickerPlacing = ref.watch(stickerPlacementProvider).isPlacing;
    final isImagePlacing = ref.watch(imagePlacementProvider).isPlacing;
    final enablePointerEvents = !widget.isReadOnly &&
        (isDrawingTool || isSelectionTool || isShapeTool || isTextTool ||
            isStickerTool || isStickerPlacing ||
            isImageTool || isImagePlacing);

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
        
        // CRITICAL FIX: Use computed transform if still at default state
        // This prevents "small square" bug on first render
        CanvasTransform effectiveTransform = transform;
        if (!canvasMode.isInfinite) {
          final isDefaultTransform = 
              transform.zoom == 1.0 && transform.offset == Offset.zero;
          if (isDefaultTransform) {
            // Compute the correct transform immediately for first frame
            // Using DEFAULT ZOOM: 1.0 (100%)
            final pageSize = Size(currentPage.size.width, currentPage.size.height);
            const defaultZoom = 1.0;
            
            final pageScreenWidth = pageSize.width * defaultZoom;
            final pageScreenHeight = pageSize.height * defaultZoom;
            
            // Center horizontally
            final offsetX = (size.width - pageScreenWidth) / 2;
            // Center vertically
            final offsetY = (size.height - pageScreenHeight) / 2;
            
            effectiveTransform = CanvasTransform(
              zoom: defaultZoom,
              offset: Offset(offsetX, offsetY),
            );
          }
        }

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

            // Canvas with gesture handlers
            Listener(
              onPointerDown: enablePointerEvents ? handlePointerDown : null,
              onPointerMove: enablePointerEvents ? handlePointerMove : null,
              onPointerUp: enablePointerEvents ? handlePointerUp : null,
              onPointerCancel: enablePointerEvents ? handlePointerCancel : null,
              behavior: HitTestBehavior.translucent,
              child: GestureDetector(
                onScaleStart: handleScaleStart,
                onScaleUpdate: handleScaleUpdate,
                onScaleEnd: handleScaleEnd,
                behavior: HitTestBehavior.opaque,
                child: ClipRect(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Transform(
                    // Apply zoom and pan transformation
                    transform: effectiveTransform.matrix,
                    alignment: Alignment.topLeft,
                      child: Stack(
                        clipBehavior: Clip.none, // Allow content outside bounds
                        children: [
                          // ═══════════════════════════════════════════════════════════
                          // LAYER 0: Page Container (LIMITED mod için)
                          // ═══════════════════════════════════════════════════════════
                          if (!canvasMode.isInfinite) ...[
                            // Sayfa gölgesi - PDF için KAPALI
                            if (canvasMode.showPageShadow &&
                                currentPage.background.type !=
                                    BackgroundType.pdf)
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
                            if (currentPage.background.type ==
                                BackgroundType.pdf) ...[
                              Positioned(
                                left: 0,
                                top: 0,
                                child: IgnorePointer(
                                  child: _buildPdfBackground(currentPage),
                                ),
                              ),
                            ],

                            // Sayfa arka planı + pattern (PDF DEĞİLSE göster)
                            if (currentPage.background.type !=
                                BackgroundType.pdf)
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
                                          color: colorScheme.effectiveBackground(
                                              currentPage.background.color),
                                          border: canvasMode.pageBorderWidth > 0
                                              ? Border.all(
                                                  color: Color(
                                                      canvasMode.pageBorderColor),
                                                  width: canvasMode.pageBorderWidth,
                                                )
                                              : null,
                                        ),
                                        child: CustomPaint(
                                          painter: PageBackgroundPatternPainter(
                                            background: currentPage.background,
                                            colorScheme: colorScheme,
                                          ),
                                          size: Size(currentPage.size.width,
                                              currentPage.size.height),
                                          isComplex: true,
                                          willChange: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],

                          // ─────────────────────────────────────────────────────────
                          // LAYER 1: Committed Images (below strokes)
                          // ─────────────────────────────────────────────────────────
                          if (images.isNotEmpty)
                            Consumer(
                              builder: (context, ref, _) {
                                final liveImage = ref.watch(
                                  imagePlacementProvider
                                      .select((s) => s.selectedImage),
                                );
                                return RepaintBoundary(
                                  child: CustomPaint(
                                    size: size,
                                    painter: ImageElementPainter(
                                      images: images,
                                      cacheManager: _imageCacheManager,
                                      overrideImage: liveImage,
                                    ),
                                    isComplex: true,
                                    willChange: liveImage != null,
                                  ),
                                );
                              },
                            ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 2: Committed Strokes (from DocumentProvider)
                          // ─────────────────────────────────────────────────────────
                          // Repaints when strokes are added/removed via provider
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: CommittedStrokesPainter(
                                strokes: strokes,
                                renderer: _renderer,
                                excludedSegments: pixelEraserPreview,
                                excludedStrokeIds: excludedStrokeIds,
                              ),
                              isComplex: true,
                              willChange: pixelEraserPreview.isNotEmpty || hasLiveTransform,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 3: Committed Shapes + Preview Shape
                          // ─────────────────────────────────────────────────────────
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: ShapePainter(
                                shapes: shapes,
                                activeShape: previewShape,
                                excludedShapeIds: excludedShapeIds,
                              ),
                              isComplex: true,
                              willChange: previewShape != null || hasLiveTransform,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 3: Committed Texts + Active Text
                          // ─────────────────────────────────────────────────────────
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: TextElementPainter(
                                texts: texts,
                                activeText: textToolState.isEditing
                                    ? textToolState.activeText
                                    : null,
                              ),
                              isComplex: true,
                              willChange: textToolState.isEditing,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 4: Active Stroke (Live Drawing)
                          // ─────────────────────────────────────────────────────────
                          // Uses ListenableBuilder to listen to DrawingController
                          // for optimal performance during drawing
                          RepaintBoundary(
                            child: ListenableBuilder(
                              listenable: _drawingController,
                              builder: (context, _) {
                                return CustomPaint(
                                  size: size,
                                  painter: ActiveStrokePainter(
                                    points: _drawingController.activePoints,
                                    style: _drawingController.activeStyle,
                                    renderer: _renderer,
                                  ),
                                  isComplex: false,
                                  willChange: true,
                                );
                              },
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 5: Straight Line Preview (for highlighter)
                          // ─────────────────────────────────────────────────────────
                          if (straightLinePreviewPoints != null &&
                              straightLinePreviewStyle != null)
                            RepaintBoundary(
                              child: CustomPaint(
                                size: size,
                                painter: ActiveStrokePainter(
                                  points: straightLinePreviewPoints,
                                  style: straightLinePreviewStyle,
                                  renderer: _renderer,
                                ),
                                isComplex: false,
                                willChange: true,
                              ),
                            ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 6: Selection Overlay
                          // ─────────────────────────────────────────────────────────
                          // Selection path and bounding box
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: SelectionPainter(
                                selection: selection,
                                previewPath: selectionPreviewPath,
                                zoom: transform.zoom,
                                hasLiveTransform: hasLiveTransform,
                              ),
                              isComplex: false,
                              willChange: true,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 7: Selected Elements with Live Transform
                          // ─────────────────────────────────────────────────────────
                          if (hasLiveTransform && selection != null)
                            RepaintBoundary(
                              child: CustomPaint(
                                size: size,
                                painter: SelectedElementsPainter(
                                  selectedStrokes: selectedStrokes,
                                  selectedShapes: selectedShapes,
                                  moveDelta: selectionUi.moveDelta,
                                  rotation: selectionUi.rotation,
                                  centerX: (selection.bounds.left + selection.bounds.right) / 2,
                                  centerY: (selection.bounds.top + selection.bounds.bottom) / 2,
                                  renderer: _renderer,
                                ),
                                isComplex: true,
                                willChange: true,
                              ),
                            ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 8: Selection Handles (for drag interactions)
                          // ─────────────────────────────────────────────────────────
                          if (selection != null)
                            SelectionHandles(
                              selection: selection,
                              onSelectionChanged: () => setState(() {}),
                            ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 9: Image Resize Handles
                          // ─────────────────────────────────────────────────────────
                          Builder(
                            builder: (context) {
                              final imgState = ref.watch(imagePlacementProvider);
                              final selected = imgState.selectedImage;
                              if (selected == null || imgState.isMoving) {
                                return const SizedBox.shrink();
                              }
                              return ImageResizeHandles(image: selected);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ───────────────────────────────────────────────────────────────────
            // Text Context Menu (must be outside gesture handlers, uses screen coordinates)
            // ───────────────────────────────────────────────────────────────────
            if (textToolState.showMenu && textToolState.menuText != null)
              TextContextMenu(
                textElement: textToolState.menuText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onEdit: isTextTool ? handleTextEdit : handleTextStyle,
                onDelete: handleTextDelete,
                onStyle: isTextTool ? handleTextStyle : null,
                onDuplicate: handleTextDuplicate,
                onMove: handleTextMove,
              ),

            // ───────────────────────────────────────────────────────────────────
            // Selection Context Menu (delete/copy/style)
            // ───────────────────────────────────────────────────────────────────
            if (selectionUi.showMenu && selection != null)
              Builder(
                builder: (context) {
                  final centerX = (selection.bounds.left + selection.bounds.right) / 2 *
                          transform.zoom +
                      transform.offset.dx;
                  final screenY = selection.bounds.top * transform.zoom +
                      transform.offset.dy -
                      50;
                  return _SelectionContextMenu(
                    left: centerX,
                    top: screenY,
                    onDelete: () => _handleSelectionDelete(selection),
                    onDuplicate: () => _handleSelectionDuplicate(selection),
                    onStyleColor: (color) => _handleSelectionColorChange(selection, color),
                  );
                },
              ),

            // ───────────────────────────────────────────────────────────────────
            // Image Context Menu (delete/duplicate/move only, no edit/style)
            // ───────────────────────────────────────────────────────────────────
            Builder(
              builder: (context) {
                final imgState = ref.watch(imagePlacementProvider);
                if (!imgState.showMenu || imgState.selectedImage == null) {
                  return const SizedBox.shrink();
                }
                final mi = imgState.selectedImage!;
                // Center menu above image
                final centerX = (mi.x + mi.width / 2) * transform.zoom +
                    transform.offset.dx;
                final screenY = mi.y * transform.zoom + transform.offset.dy - 50;
                const menuWidth = 81.0; // 40 + 1 + 40
                return Positioned(
                  left: centerX - menuWidth / 2,
                  top: screenY,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) {},
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _imageMenuButton(
                              StarNoteIcons.trash, 'Sil',
                              handleImageDelete, Colors.red,
                            ),
                            _imageMenuDivider(),
                            _imageMenuButton(
                              StarNoteIcons.copy, 'Kopyala',
                              handleImageDuplicate, null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ───────────────────────────────────────────────────────────────────
            // Text Input Overlay (must be outside gesture handlers)
            // ───────────────────────────────────────────────────────────────────
            if (textToolState.isEditing && textToolState.activeText != null)
              TextInputOverlay(
                textElement: textToolState.activeText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onTextChanged: (updatedText) {
                  ref.read(textToolProvider.notifier).updateText(updatedText);
                },
                onEditingComplete: () => finishTextEditing(),
                onCancel: () => cancelTextEditing(),
              ),

            // ───────────────────────────────────────────────────────────────────
            // Text Style Popup (must be outside gesture handlers)
            // ───────────────────────────────────────────────────────────────────
            if (textToolState.showStylePopup && textToolState.styleText != null)
              TextStylePopup(
                textElement: textToolState.styleText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onStyleChanged: handleTextStyleChanged,
                onClose: () =>
                    ref.read(textToolProvider.notifier).hideStylePopup(),
                stickerMode: !isTextTool,
              ),

            // ───────────────────────────────────────────────────────────────────
            // Text Move Mode Indicator
            // ───────────────────────────────────────────────────────────────────
            if (textToolState.isMoving)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(StarNoteIcons.touchApp,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Taşımak için bir yere dokunun',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => ref
                              .read(textToolProvider.notifier)
                              .cancelMoving(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const PhosphorIcon(StarNoteIcons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ───────────────────────────────────────────────────────────────────
            // Image Move Mode Indicator
            // ───────────────────────────────────────────────────────────────────
            Builder(
              builder: (context) {
                final imgState = ref.watch(imagePlacementProvider);
                if (!imgState.isMoving) return const SizedBox.shrink();
                return Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(StarNoteIcons.touchApp,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Tasimak icin bir yere dokunun',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => ref
                                .read(imagePlacementProvider.notifier)
                                .cancelMoving(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const PhosphorIcon(StarNoteIcons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ───────────────────────────────────────────────────────────────────
            // Sticker Placement Mode Indicator
            // ───────────────────────────────────────────────────────────────────
            Builder(
              builder: (context) {
                final stickerState = ref.watch(stickerPlacementProvider);
                if (!stickerState.isPlacing ||
                    stickerState.selectedEmoji == null) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(stickerState.selectedEmoji!,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          const Text(
                            'Yerleştirmek için dokunun',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => ref
                                .read(stickerPlacementProvider.notifier)
                                .cancel(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ───────────────────────────────────────────────────────────────────
            // Image Placement Mode Indicator
            // ───────────────────────────────────────────────────────────────────
            Builder(
              builder: (context) {
                final imageState = ref.watch(imagePlacementProvider);
                if (!imageState.isPlacing) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(StarNoteIcons.image,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Resmi yerlesirmek icin dokunun',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => ref
                                .read(imagePlacementProvider.notifier)
                                .cancel(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ───────────────────────────────────────────────────────────────────
            // Eraser Cursor Overlay (using screen coordinates)
            // ───────────────────────────────────────────────────────────────────
            if (isEraserTool)
              EraserCursorWidget(
                cursorPosition: eraserCursorPosition ?? Offset.zero,
                isVisible: eraserCursorPosition != null,
                lassoPoints: lassoEraserPoints,
              ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// SELECTION CONTEXT MENU
// =============================================================================

/// Floating context menu for selection actions (delete, copy, style).
class _SelectionContextMenu extends StatelessWidget {
  final double left;
  final double top;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final ValueChanged<Color> onStyleColor;

  static const _quickColors = [
    Color(0xFF000000),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
  ];

  const _SelectionContextMenu({
    required this.left,
    required this.top,
    required this.onDelete,
    required this.onDuplicate,
    required this.onStyleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left - 100,
      top: top,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {},
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuButton(
                      StarNoteIcons.trash,
                      'Sil',
                      onDelete,
                      Colors.red,
                    ),
                    _divider(),
                    _menuButton(
                      StarNoteIcons.copy,
                      'Kopyala',
                      onDuplicate,
                      null,
                    ),
                  ],
                ),
                // Quick color row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _quickColors
                        .map((c) => _colorDot(c))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
    PhosphorIconData icon,
    String tooltip,
    VoidCallback onTap,
    Color? color,
  ) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: PhosphorIcon(icon, size: 20, color: color ?? Colors.black87),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 24, color: Colors.grey[300]);
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => onStyleColor(color),
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
      ),
    );
  }
}
