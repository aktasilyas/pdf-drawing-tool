import 'package:drawing_core/drawing_core.dart';

/// Enum representing all available drawing tool types in the UI.
///
/// This enum is used by the UI layer to identify which tool is currently
/// selected and to determine which settings panel to show.
enum ToolType {
  // PEN TOOLS
  /// Fountain pen - pressure-sensitive with tapered ends.
  fountainPen,

  /// Pencil - matte with slight texture.
  pencil,

  /// Hard pencil - lighter tones for sketching.
  hardPencil,

  /// Ballpoint pen - standard pen with consistent line width.
  ballpointPen,

  /// Gel pen - smooth and vibrant colors.
  gelPen,

  /// Dashed pen - for diagrams and emphasis.
  dashedPen,

  /// Highlighter - semi-transparent strokes for highlighting.
  highlighter,

  /// Brush pen - pressure-sensitive with variable width.
  brushPen,

  /// Neon highlighter - with glow effect.
  neonHighlighter,

  /// Ruler pen - draws perfectly straight lines.
  rulerPen,

  // ERASER TOOLS
  /// Pixel eraser - erases specific pixels/parts of strokes.
  pixelEraser,

  /// Stroke eraser - removes entire strokes.
  strokeEraser,

  /// Lasso eraser - select and erase an area.
  lassoEraser,

  // OTHER TOOLS
  /// Shapes - draw geometric shapes.
  shapes,

  /// Text - add text boxes.
  text,

  /// Sticker - add stickers/images.
  sticker,

  /// Image - insert images.
  image,

  /// Selection - select and manipulate objects.
  selection,

  /// Pan/Zoom - navigate the canvas.
  panZoom,

  /// Laser pointer - temporary pointer for presentations.
  laserPointer,

  /// Sticky note - add colored sticky notes to canvas.
  stickyNote,

  /// Toolbar settings - configure toolbar layout and tools.
  toolbarSettings;

  /// Maps ToolType to PenType for pen tools.
  /// Returns null for non-pen tools.
  PenType? get penType {
    switch (this) {
      case ToolType.fountainPen:
        return PenType.fountainPen;
      case ToolType.pencil:
        return PenType.pencil;
      case ToolType.hardPencil:
        return PenType.hardPencil;
      case ToolType.ballpointPen:
        return PenType.ballpointPen;
      case ToolType.gelPen:
        return PenType.gelPen;
      case ToolType.dashedPen:
        return PenType.dashedPen;
      case ToolType.highlighter:
        return PenType.highlighter;
      case ToolType.brushPen:
        return PenType.brushPen;
      case ToolType.neonHighlighter:
        return PenType.neonHighlighter;
      case ToolType.rulerPen:
        return PenType.rulerPen;
      default:
        return null;
    }
  }

  /// Whether this is a pen-type drawing tool.
  bool get isPenTool => penType != null;
}
