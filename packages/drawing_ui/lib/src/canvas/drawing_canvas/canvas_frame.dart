part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Immutable snapshot of everything `build` reads from providers and State.
///
/// Built once per `build` by `_readFrame` and handed to the layer builders.
class _CanvasFrame {
  final List<core.Layer> allLayers;
  final int activeLayerIndex;
  final bool activeLayerVisible;
  final double activeLayerOpacity;
  final List<core.Stroke> strokes;
  final List<core.Shape> shapes;
  final List<core.TextElement> texts;
  final List<core.ImageElement> images;
  final List<String> elementOrder;
  final CanvasTransform transform;
  final core.Selection? selection;
  final SelectionUiState selectionUi;
  final TextToolState textToolState;
  final core.CanvasMode canvasMode;
  final core.Page currentPage;
  final CanvasColorScheme colorScheme;
  final Offset? eraserCursorPosition;
  final List<Offset> lassoEraserPoints;
  final bool isEraserTool;
  final Map<String, List<int>> pixelEraserPreview;
  final Set<String> strokeEraserPreview;
  final List<core.DrawingPoint>? selectionPreviewPath;
  final bool hasLiveTransform;
  final Set<String> excludedStrokeIds;
  final Set<String> excludedShapeIds;
  final Set<String> excludedImageIds;
  final Set<String> excludedTextIds;
  final List<core.Stroke> selectedStrokes;
  final List<core.Shape> selectedShapes;
  final List<core.ImageElement> selectedImages;
  final List<core.TextElement> selectedTexts;
  final core.Shape? previewShape;
  final List<core.DrawingPoint>? straightLinePreviewPoints;
  final core.StrokeStyle? straightLinePreviewStyle;
  final List<core.StickyNote> stickyNotes;
  final bool isTextTool;
  final bool isStickyNoteTool;
  final bool enablePointerEvents;

  _CanvasFrame({
    required this.allLayers,
    required this.activeLayerIndex,
    required this.activeLayerVisible,
    required this.activeLayerOpacity,
    required this.strokes,
    required this.shapes,
    required this.texts,
    required this.images,
    required this.elementOrder,
    required this.transform,
    required this.selection,
    required this.selectionUi,
    required this.textToolState,
    required this.canvasMode,
    required this.currentPage,
    required this.colorScheme,
    required this.eraserCursorPosition,
    required this.lassoEraserPoints,
    required this.isEraserTool,
    required this.pixelEraserPreview,
    required this.strokeEraserPreview,
    required this.selectionPreviewPath,
    required this.hasLiveTransform,
    required this.excludedStrokeIds,
    required this.excludedShapeIds,
    required this.excludedImageIds,
    required this.excludedTextIds,
    required this.selectedStrokes,
    required this.selectedShapes,
    required this.selectedImages,
    required this.selectedTexts,
    required this.previewShape,
    required this.straightLinePreviewPoints,
    required this.straightLinePreviewStyle,
    required this.stickyNotes,
    required this.isTextTool,
    required this.isStickyNoteTool,
    required this.enablePointerEvents,
  });
}
