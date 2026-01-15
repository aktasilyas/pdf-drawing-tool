import 'package:drawing_core/drawing_core.dart';

/// Enum representing all available drawing tool types in the UI.
///
/// This enum is used by the UI layer to identify which tool is currently
/// selected and to determine which settings panel to show.
enum ToolType {
  // PEN TOOLS (10 types)
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

  /// Marker - flat and opaque, bold strokes.
  marker,

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
  laserPointer;

  /// Human-readable display name for the tool.
  String get displayName {
    switch (this) {
      case ToolType.pencil:
        return 'Kurşun Kalem';
      case ToolType.hardPencil:
        return 'Sert Kalem';
      case ToolType.ballpointPen:
        return 'Tükenmez Kalem';
      case ToolType.gelPen:
        return 'Jel Kalem';
      case ToolType.dashedPen:
        return 'Kesik Çizgi';
      case ToolType.highlighter:
        return 'Fosforlu Kalem';
      case ToolType.brushPen:
        return 'Fırça Kalem';
      case ToolType.marker:
        return 'Keçeli Kalem';
      case ToolType.neonHighlighter:
        return 'Neon Fosforlu';
      case ToolType.rulerPen:
        return 'Cetvelli Kalem';
      case ToolType.pixelEraser:
        return 'Silgi';
      case ToolType.strokeEraser:
        return 'Çizgi Silgisi';
      case ToolType.lassoEraser:
        return 'Kement Silgisi';
      case ToolType.shapes:
        return 'Şekiller';
      case ToolType.text:
        return 'Metin';
      case ToolType.sticker:
        return 'Çıkartma';
      case ToolType.image:
        return 'Resim';
      case ToolType.selection:
        return 'Seçim';
      case ToolType.panZoom:
        return 'Kaydır/Yakınlaştır';
      case ToolType.laserPointer:
        return 'Lazer İşaretçi';
    }
  }

  /// Maps ToolType to PenType for pen tools.
  /// Returns null for non-pen tools.
  PenType? get penType {
    switch (this) {
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
      case ToolType.marker:
        return PenType.marker;
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
