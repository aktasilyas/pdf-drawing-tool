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
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
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
        _CanvasInkLayers {
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
      _lastPageSize = null;
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

  @override
  Widget build(BuildContext context) {
    final f = _readFrame();
    final allLayers = f.allLayers;
    final activeLayerIndex = f.activeLayerIndex;
    final activeLayerVisible = f.activeLayerVisible;
    final transform = f.transform;
    final selection = f.selection;
    final selectionUi = f.selectionUi;
    final textToolState = f.textToolState;
    final canvasMode = f.canvasMode;
    final currentPage = f.currentPage;
    final colorScheme = f.colorScheme;
    final eraserCursorPosition = f.eraserCursorPosition;
    final lassoEraserPoints = f.lassoEraserPoints;
    final isEraserTool = f.isEraserTool;
    final selectionPreviewPath = f.selectionPreviewPath;
    final hasLiveTransform = f.hasLiveTransform;
    final selectedStrokes = f.selectedStrokes;
    final selectedShapes = f.selectedShapes;
    final selectedImages = f.selectedImages;
    final selectedTexts = f.selectedTexts;
    final isTextTool = f.isTextTool;
    final isStickyNoteTool = f.isStickyNoteTool;
    final enablePointerEvents = f.enablePointerEvents;

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
                child: RepaintBoundary(
                  key: ref.read(canvasBoundaryKeyProvider),
                  child: ClipRect(
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: Transform(
                        // Apply zoom and pan transformation
                        transform: effectiveTransform.matrix,
                        alignment: Alignment.topLeft,
                        child: Stack(
                          clipBehavior:
                              Clip.none, // Allow content outside bounds
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
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
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
                                            color: colorScheme
                                                .effectiveBackground(currentPage
                                                    .background.color),
                                            border:
                                                canvasMode.pageBorderWidth > 0
                                                    ? Border.all(
                                                        color: Color(canvasMode
                                                            .pageBorderColor),
                                                        width: canvasMode
                                                            .pageBorderWidth,
                                                      )
                                                    : null,
                                          ),
                                          child: PageBackgroundView(
                                            background: currentPage.background,
                                            colorScheme: colorScheme,
                                            pageSize: Size(
                                                currentPage.size.width,
                                                currentPage.size.height),
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
                            for (int i = 0;
                                i < activeLayerIndex && i < allLayers.length;
                                i++)
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
                              _buildActiveLayerContent(
                                  f, size, effectiveTransform),

                            // ─────────────────────────────────────────────────────────
                            // PASSIVE LAYERS ABOVE ACTIVE
                            // ─────────────────────────────────────────────────────────
                            for (int i = activeLayerIndex + 1;
                                i < allLayers.length;
                                i++)
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
                            ..._buildLiveInkLayers(f, size),

                            // ─────────────────────────────────────────────────────────
                            // LAYER 6: Selection Overlay
                            // ─────────────────────────────────────────────────────────
                            // Selection path and bounding box
                            RepaintBoundary(
                              child: CustomPaint(
                                size: size,
                                painter: SelectionPainter(
                                  selection: selection,
                                  selectionColor:
                                      Theme.of(context).colorScheme.primary,
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
                                    centerX: (selection.bounds.left +
                                            selection.bounds.right) /
                                        2,
                                    centerY: (selection.bounds.top +
                                            selection.bounds.bottom) /
                                        2,
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
                                  return StickyNoteResizeHandles(
                                      note: selected);
                                }
                                return IgnorePointer(
                                  child: CustomPaint(
                                    painter: StickyNoteHandlesPainter(
                                      note: selected,
                                      selectionColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
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
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(width: 8),
                          Text(
                            'Yerleştirmek için dokunun',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
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
                          PhosphorIcon(ElyanotesIcons.image,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Resmi yerlesirmek icin dokunun',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _noteColors.map((c) => _colorDot(c)).toList(),
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
                          PhosphorIcon(ElyanotesIcons.trash,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('Sil',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.red)),
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
