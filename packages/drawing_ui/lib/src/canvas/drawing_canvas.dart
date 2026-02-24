import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_core/drawing_core.dart' show BackgroundType;
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/passive_layer_painter.dart';
import 'package:drawing_ui/src/canvas/selection_painter.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/unified_element_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_handles_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_resize_handles.dart';
import 'package:drawing_ui/src/canvas/selected_elements_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_helpers.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';
import 'package:drawing_ui/src/canvas/laser_controller.dart';
import 'package:drawing_ui/src/canvas/laser_overlay_widget.dart';
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
import 'package:drawing_ui/src/providers/sticky_note_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';

// =============================================================================
// DRAWING CANVAS WIDGET
// =============================================================================

/// Wraps [child] with [Opacity] only when opacity < 1.0.
Widget _wrapOpacity(double opacity, Widget child) {
  if (opacity >= 1.0) return child;
  return Opacity(opacity: opacity, child: child);
}

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

  const DrawingCanvas({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.canvasMode,
    this.isReadOnly = false,
    this.onPageSwipe,
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

  /// Controller for managing temporary laser pointer strokes.
  late final LaserController _laserController;

  /// Whether a laser drawing operation is in progress.
  bool _isLaserDrawing = false;

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

  // ─────────────────────────────────────────────────────────────────────────
  // PIXEL ERASER TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Accumulated segment hits for pixel eraser during a gesture.
  final Map<String, List<int>> _pixelEraseHits = {};

  /// Original strokes affected by pixel eraser (for undo).
  final List<core.Stroke> _pixelEraseOriginalStrokes = [];

  /// Note ID -> set of internal stroke IDs erased in current gesture.
  final Map<String, Set<String>> _erasedNoteStrokeIds = {};

  /// Note ID -> set of internal shape IDs erased in current gesture.
  final Map<String, Set<String>> _erasedNoteShapeIds = {};

  /// Note ID -> (stroke ID -> segment indices) for pixel erasure inside notes.
  final Map<String, Map<String, List<int>>> _pixelEraseNoteHits = {};

  /// Note ID -> original strokes for pixel erasure inside notes.
  final Map<String, List<core.Stroke>> _pixelEraseNoteOriginalStrokes = {};

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
    _laserController = LaserController();
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
    _laserController.dispose();
    _imageCacheManager.dispose();
    super.dispose();
  }

  void _handleStickyNoteDelete(core.StickyNote note) {
    final document = ref.read(documentProvider);
    final command = core.RemoveStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      stickyNoteId: note.id,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(stickyNotePlacementProvider.notifier).deselectNote();
  }

  void _handleStickyNoteColorChange(core.StickyNote note, int color) {
    final updated = note.copyWith(color: color);
    final document = ref.read(documentProvider);
    final command = core.UpdateStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      newNote: updated,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(stickyNotePlacementProvider.notifier).selectNote(updated);
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

    // Check if viewport size changed significantly
    final needsReInit = !_hasInitialized ||
        _isOrientationChanged(viewportSize) ||
        _isSignificantHeightChange(viewportSize);
    if (!needsReInit) return;

    // Mark as initialized immediately to prevent multiple calls
    _hasInitialized = true;
    _lastViewportSize = viewportSize;

    // Schedule initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(canvasViewportSizeProvider.notifier).state = viewportSize;
      ref.read(canvasTransformProvider.notifier).initializeForPage(
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
          );
    });
  }

  /// Check if orientation changed (width/height swapped).
  bool _isOrientationChanged(Size newSize) {
    final lastSize = _lastViewportSize;
    if (lastSize == null) return false;

    final wasPortrait = lastSize.height > lastSize.width;
    final isPortrait = newSize.height > newSize.width;

    return wasPortrait != isPortrait;
  }

  /// Detect significant viewport height change (keyboard show/hide).
  /// Keyboards are typically > 200px, so 100px threshold avoids false positives.
  bool _isSignificantHeightChange(Size newSize) {
    final lastSize = _lastViewportSize;
    if (lastSize == null) return false;
    return (newSize.height - lastSize.height).abs() > 100;
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
  Map<String, List<int>> get pixelEraseHits => _pixelEraseHits;

  @override
  List<core.Stroke> get pixelEraseOriginalStrokes => _pixelEraseOriginalStrokes;

  @override
  Map<String, Set<String>> get erasedNoteStrokeIds => _erasedNoteStrokeIds;

  @override
  Map<String, Set<String>> get erasedNoteShapeIds => _erasedNoteShapeIds;

  @override
  Map<String, Map<String, List<int>>> get pixelEraseNoteHits =>
      _pixelEraseNoteHits;

  @override
  Map<String, List<core.Stroke>> get pixelEraseNoteOriginalStrokes =>
      _pixelEraseNoteOriginalStrokes;

  @override
  LaserController get laserController => _laserController;

  @override
  bool get isLaserDrawing => _isLaserDrawing;
  @override
  set isLaserDrawing(bool value) => _isLaserDrawing = value;

  @override
  Offset? get lastFocalPoint => _lastFocalPoint;
  @override
  set lastFocalPoint(Offset? value) => _lastFocalPoint = value;

  @override
  double? get lastScale => _lastScale;
  @override
  set lastScale(double? value) => _lastScale = value;

  /// Sticky note that constrains the current stroke (if drawing inside one).
  core.StickyNote? _drawingInsideNote;
  @override
  core.StickyNote? get drawingInsideNote => _drawingInsideNote;
  @override
  set drawingInsideNote(core.StickyNote? value) => _drawingInsideNote = value;

  /// Focal point at the start of a scale gesture (for swipe detection).
  Offset? _scaleStartFocalPoint;
  @override
  Offset? get scaleStartFocalPoint => _scaleStartFocalPoint;
  @override
  set scaleStartFocalPoint(Offset? value) => _scaleStartFocalPoint = value;

  @override
  ValueChanged<int>? get onPageSwipe => widget.onPageSwipe;

  /// Whether the current scale gesture has been classified as zoom (not swipe).
  bool _scaleGestureIsZoom = false;
  @override
  bool get scaleGestureIsZoom => _scaleGestureIsZoom;
  @override
  set scaleGestureIsZoom(bool value) => _scaleGestureIsZoom = value;

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final allLayers = ref.watch(allLayersProvider);
    final activeLayerIndex = ref.watch(activeLayerIndexProvider);
    final activeLayerValid = activeLayerIndex >= 0 &&
        activeLayerIndex < allLayers.length;
    final activeLayerVisible = activeLayerValid &&
        allLayers[activeLayerIndex].isVisible;
    final activeLayerOpacity = activeLayerValid
        ? allLayers[activeLayerIndex].opacity
        : 1.0;
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
            current.background.pdfFilePath != null &&
            current.background.pdfPageIndex != null) {
          // pdfPageIndex kullan (1-based), document page index değil
          prefetchOnPageChange(ref, current.background.pdfPageIndex!);
        }
      }
    });

    // Eraser cursor state
    final eraserCursorPosition = ref.watch(eraserCursorPositionProvider);
    final lassoEraserPoints = ref.watch(lassoEraserPointsProvider);
    final isEraserTool = ref.watch(isEraserToolProvider);
    final pixelEraserPreview = ref.watch(pixelEraserPreviewProvider);
    final strokeEraserPreview = ref.watch(strokeEraserPreviewProvider);

    // Selection tool preview path
    List<core.DrawingPoint>? selectionPreviewPath;
    if (isSelectionTool && _isSelecting) {
      selectionPreviewPath = ref.read(activeSelectionToolProvider).currentPath;
    }

    // Watch images and elementOrder for active layer
    final images = ref.watch(activeLayerImagesProvider);
    final elementOrder = activeLayerValid
        ? allLayers[activeLayerIndex].elementOrder
        : const <String>[];

    // Compute excluded IDs + selected elements for live transform
    final hasLiveTransform = selectionUi.hasTransform;
    Set<String> excludedStrokeIds = const {};
    Set<String> excludedShapeIds = const {};
    Set<String> excludedImageIds = const {};
    Set<String> excludedTextIds = const {};
    List<core.Stroke> selectedStrokes = const [];
    List<core.Shape> selectedShapes = const [];
    List<core.ImageElement> selectedImages = const [];
    List<core.TextElement> selectedTexts = const [];

    if (selection != null && hasLiveTransform) {
      excludedStrokeIds = selection.selectedStrokeIds.toSet();
      excludedShapeIds = selection.selectedShapeIds.toSet();
      excludedImageIds = selection.selectedImageIds.toSet();
      excludedTextIds = selection.selectedTextIds.toSet();

      selectedStrokes = strokes
          .where((s) => excludedStrokeIds.contains(s.id))
          .toList();
      selectedShapes = shapes
          .where((s) => excludedShapeIds.contains(s.id))
          .toList();
      selectedImages = images
          .where((i) => excludedImageIds.contains(i.id))
          .toList();
      selectedTexts = texts
          .where((t) => excludedTextIds.contains(t.id))
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

    // Watch sticky notes for active layer
    final stickyNotes = ref.watch(activeLayerStickyNotesProvider);

    // Enable pointer events for drawing tools, selection tool, shape tool, text tool,
    // sticker placement mode, image tool, and image placement mode.
    // In read-only mode, all drawing pointer events are disabled (pan/zoom still works)
    final isTextTool = currentTool == ToolType.text;
    final isStickerTool = currentTool == ToolType.sticker;
    final isImageTool = currentTool == ToolType.image;
    final isStickerPlacing = ref.watch(stickerPlacementProvider).isPlacing;
    final isImagePlacing = ref.watch(imagePlacementProvider).isPlacing;
    final isLaserTool = currentTool == ToolType.laserPointer;
    final isStickyNoteTool = currentTool == ToolType.stickyNote;
    final enablePointerEvents = !widget.isReadOnly &&
        (isDrawingTool || isSelectionTool || isShapeTool || isTextTool ||
            isStickerTool || isStickerPlacing ||
            isImageTool || isImagePlacing || isLaserTool || isStickyNoteTool);

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
            // Compute fit-to-screen transform for first frame
            final pageSize = Size(currentPage.size.width, currentPage.size.height);
            final fitWidth = size.width / pageSize.width;
            final fitHeight = size.height / pageSize.height;
            // Use fit-width with padding on narrow (portrait) screens
            final fitZoom = (fitWidth < fitHeight)
                ? fitWidth * 0.96
                : fitHeight;

            final pageScreenWidth = pageSize.width * fitZoom;
            final pageScreenHeight = pageSize.height * fitZoom;
            final offsetX = (size.width - pageScreenWidth) / 2;
            final offsetY = (size.height - pageScreenHeight) / 2;

            effectiveTransform = CanvasTransform(
              zoom: fitZoom,
              offset: Offset(offsetX, offsetY),
              baselineZoom: fitZoom,
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
                          // PASSIVE LAYERS BELOW ACTIVE
                          // ─────────────────────────────────────────────────────────
                          for (int i = 0; i < activeLayerIndex && i < allLayers.length; i++)
                            if (allLayers[i].isVisible)
                              PassiveLayerStack(
                                layer: allLayers[i],
                                renderer: _renderer,
                                imageCacheManager: _imageCacheManager,
                              ),

                          // ─────────────────────────────────────────────────────────
                          // ACTIVE LAYER: Committed content (hidden when !isVisible)
                          // ─────────────────────────────────────────────────────────
                          if (activeLayerVisible)
                            _wrapOpacity(activeLayerOpacity, Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Unified element painter: strokes, shapes, images, texts
                                RepaintBoundary(
                                  child: CustomPaint(
                                    size: size,
                                    painter: UnifiedElementPainter(
                                      strokes: strokes,
                                      shapes: shapes,
                                      images: images,
                                      texts: texts,
                                      elementOrder: elementOrder,
                                      renderer: _renderer,
                                      cacheManager: _imageCacheManager,
                                      activeShape: previewShape,
                                      activeText: textToolState.isEditing
                                          ? textToolState.activeText
                                          : null,
                                      excludedStrokeIds: strokeEraserPreview.isNotEmpty
                                          ? {...excludedStrokeIds, ...strokeEraserPreview}
                                          : excludedStrokeIds,
                                      excludedShapeIds: excludedShapeIds,
                                      excludedImageIds: excludedImageIds,
                                      excludedTextIds: excludedTextIds,
                                      pixelEraserPreview: pixelEraserPreview,
                                      strokeEraserPreview: strokeEraserPreview,
                                    ),
                                    isComplex: true,
                                    willChange: pixelEraserPreview.isNotEmpty ||
                                        strokeEraserPreview.isNotEmpty ||
                                        previewShape != null ||
                                        textToolState.isEditing ||
                                        hasLiveTransform,
                                  ),
                                ),
                                // Committed Sticky Notes
                                if (stickyNotes.isNotEmpty)
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final liveNote = ref.watch(
                                        stickyNotePlacementProvider
                                            .select((s) => s.selectedNote),
                                      );
                                      return RepaintBoundary(
                                        child: CustomPaint(
                                          size: size,
                                          painter: StickyNotePainter(
                                            stickyNotes: stickyNotes,
                                            renderer: _renderer,
                                            overrideNote: liveNote,
                                          ),
                                          isComplex: true,
                                          willChange: liveNote != null,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            )),

                          // ─────────────────────────────────────────────────────────
                          // PASSIVE LAYERS ABOVE ACTIVE
                          // ─────────────────────────────────────────────────────────
                          for (int i = activeLayerIndex + 1; i < allLayers.length; i++)
                            if (allLayers[i].isVisible)
                              PassiveLayerStack(
                                layer: allLayers[i],
                                renderer: _renderer,
                                imageCacheManager: _imageCacheManager,
                              ),

                          // ─────────────────────────────────────────────────────────
                          // ACTIVE LAYER: Active Stroke (Live Drawing)
                          // ─────────────────────────────────────────────────────────
                          // Uses ListenableBuilder to listen to DrawingController
                          // for optimal performance during drawing
                          if (activeLayerVisible)
                            _wrapOpacity(
                              activeLayerOpacity,
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
                            ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 4.5: Laser Pointer Overlay
                          // ─────────────────────────────────────────────────────────
                          LaserOverlayWidget(
                            controller: _laserController,
                            size: size,
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
                                  selectedImages: selectedImages,
                                  selectedTexts: selectedTexts,
                                  imageCacheManager: _imageCacheManager,
                                  moveDelta: selectionUi.moveDelta,
                                  rotation: selectionUi.rotation,
                                  scaleX: selectionUi.scaleX,
                                  scaleY: selectionUi.scaleY,
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
                          if (selection != null && selection.isNotEmpty)
                            SelectionHandles(
                              selection: selection,
                              onSelectionChanged: () => setState(() {}),
                            ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 9: Sticky Note Resize Handles
                          // ─────────────────────────────────────────────────────────
                          Builder(
                            builder: (context) {
                              final noteState =
                                  ref.watch(stickyNotePlacementProvider);
                              final selected = noteState.selectedNote;
                              if (selected == null ||
                                  noteState.isMoving ||
                                  selected.minimized) {
                                return const SizedBox.shrink();
                              }
                              // On stickyNote tool: full interactive handles.
                              // On other tools: paint-only (visible but no gesture).
                              if (isStickyNoteTool) {
                                return StickyNoteResizeHandles(note: selected);
                              }
                              return IgnorePointer(
                                child: CustomPaint(
                                  painter: StickyNoteHandlesPainter(
                                      note: selected),
                                  child: const SizedBox.expand(),
                                ),
                              );
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
            // Selection Toolbar (floating toolbar with quick actions + overflow)
            // ───────────────────────────────────────────────────────────────────
            if (selectionUi.showMenu && selection != null)
              SelectionToolbar(
                selection: selection,
                cacheManager: _imageCacheManager,
              ),

            // ───────────────────────────────────────────────────────────────────
            // Paste Context Menu (long press on empty canvas)
            // ───────────────────────────────────────────────────────────────────
            Builder(
              builder: (context) {
                final pasteMenu = ref.watch(pasteMenuProvider);
                if (pasteMenu == null) return const SizedBox.shrink();
                return PasteContextMenu(state: pasteMenu);
              },
            ),

            // ───────────────────────────────────────────────────────────────────
            // Sticky Note Context Menu (color picker + delete)
            // ───────────────────────────────────────────────────────────────────
            Builder(
              builder: (context) {
                final noteState = ref.watch(stickyNotePlacementProvider);
                if (!noteState.showMenu || noteState.selectedNote == null) {
                  return const SizedBox.shrink();
                }
                final sn = noteState.selectedNote!;
                final centerX = (sn.x + sn.width / 2) * transform.zoom +
                    transform.offset.dx;
                final screenY =
                    sn.y * transform.zoom + transform.offset.dy - 50;
                return _StickyNoteContextMenu(
                  left: centerX,
                  top: screenY,
                  onDelete: () => _handleStickyNoteDelete(sn),
                  onColorChange: (color) =>
                      _handleStickyNoteColorChange(sn, color),
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
// STICKY NOTE CONTEXT MENU
// =============================================================================

/// Floating context menu for sticky note actions (color change, delete).
class _StickyNoteContextMenu extends StatelessWidget {
  final double left;
  final double top;
  final VoidCallback onDelete;
  final ValueChanged<int> onColorChange;

  static const _noteColors = [
    0xFFFFF3CD, // Yellow
    0xFFF8D7DA, // Pink
    0xFFD1ECF1, // Blue
    0xFFD4EDDA, // Green
    0xFFFFE0CC, // Orange
    0xFFE8D5F5, // Purple
  ];

  const _StickyNoteContextMenu({
    required this.left,
    required this.top,
    required this.onDelete,
    required this.onColorChange,
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
                // Color dots row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _noteColors
                        .map((c) => _colorDot(c))
                        .toList(),
                  ),
                ),
                // Delete button
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: _noteColors.length * 28.0 + 12,
                      height: 36,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(StarNoteIcons.trash,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          const Text('Sil',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorDot(int colorValue) {
    return GestureDetector(
      onTap: () => onColorChange(colorValue),
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
      ),
    );
  }
}
