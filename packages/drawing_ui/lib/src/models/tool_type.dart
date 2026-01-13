/// Enum representing all available drawing tool types in the UI.
///
/// This enum is used by the UI layer to identify which tool is currently
/// selected and to determine which settings panel to show.
enum ToolType {
  /// Ballpoint pen - standard pen with consistent line width.
  ballpointPen,

  /// Fountain pen - pen with variable line width based on pressure/speed.
  fountainPen,

  /// Pencil - textured strokes that simulate a real pencil.
  pencil,

  /// Brush - wide strokes with soft edges.
  brush,

  /// Highlighter - semi-transparent strokes for highlighting.
  highlighter,

  /// Pixel eraser - erases specific pixels/parts of strokes.
  pixelEraser,

  /// Stroke eraser - removes entire strokes.
  strokeEraser,

  /// Lasso eraser - select and erase an area.
  lassoEraser,

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
      case ToolType.ballpointPen:
        return 'Tükenmez Kalem';
      case ToolType.fountainPen:
        return 'Dolma Kalem';
      case ToolType.pencil:
        return 'Kurşun Kalem';
      case ToolType.brush:
        return 'Fırça';
      case ToolType.highlighter:
        return 'Fosforlu Kalem';
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
}
