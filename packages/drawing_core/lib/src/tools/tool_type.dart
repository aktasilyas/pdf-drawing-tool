/// Enumerates all available drawing tool types.
///
/// Each tool type represents a distinct drawing behavior and UI configuration.
enum ToolType {
  /// Ballpoint pen with circular nib and moderate pressure sensitivity.
  ballpointPen,

  /// Fountain pen with angled elliptical nib for calligraphy effects.
  fountainPen,

  /// Pencil with subtle texture and natural feel.
  pencil,

  /// Brush with high pressure sensitivity and variable width.
  brush,

  /// Highlighter with rectangular nib and transparency.
  highlighter,

  /// Pixel eraser that clears individual pixels.
  pixelEraser,

  /// Stroke eraser that removes entire strokes.
  strokeEraser,

  /// Lasso eraser for selecting and removing areas.
  lassoEraser,

  /// Laser pointer for temporary annotations.
  laserPointer,

  /// Shape tool for drawing geometric shapes.
  shapes,

  /// Text tool for adding text boxes.
  text,

  /// Sticker tool for placing stickers.
  sticker,

  /// Image tool for inserting images.
  image,

  /// Selection tool for selecting and manipulating content.
  selection,

  /// Pan/zoom tool for navigating the canvas.
  panZoom,
}

/// Extension methods for [ToolType].
extension ToolTypeExtension on ToolType {
  /// Returns true if this tool creates strokes.
  bool get isDrawingTool {
    return switch (this) {
      ToolType.ballpointPen ||
      ToolType.fountainPen ||
      ToolType.pencil ||
      ToolType.brush ||
      ToolType.highlighter =>
        true,
      _ => false,
    };
  }

  /// Returns true if this tool is an eraser variant.
  bool get isEraser {
    return switch (this) {
      ToolType.pixelEraser ||
      ToolType.strokeEraser ||
      ToolType.lassoEraser =>
        true,
      _ => false,
    };
  }

  /// Returns true if this tool creates objects (shapes, text, stickers, images).
  bool get isObjectTool {
    return switch (this) {
      ToolType.shapes ||
      ToolType.text ||
      ToolType.sticker ||
      ToolType.image =>
        true,
      _ => false,
    };
  }

  /// Returns a human-readable display name for this tool.
  String get displayName {
    return switch (this) {
      ToolType.ballpointPen => 'Ballpoint Pen',
      ToolType.fountainPen => 'Fountain Pen',
      ToolType.pencil => 'Pencil',
      ToolType.brush => 'Brush',
      ToolType.highlighter => 'Highlighter',
      ToolType.pixelEraser => 'Pixel Eraser',
      ToolType.strokeEraser => 'Stroke Eraser',
      ToolType.lassoEraser => 'Lasso Eraser',
      ToolType.laserPointer => 'Laser Pointer',
      ToolType.shapes => 'Shapes',
      ToolType.text => 'Text',
      ToolType.sticker => 'Sticker',
      ToolType.image => 'Image',
      ToolType.selection => 'Selection',
      ToolType.panZoom => 'Pan & Zoom',
    };
  }

  /// Returns the icon name for this tool.
  ///
  /// Used for loading tool icons from assets.
  String get iconName {
    return switch (this) {
      ToolType.ballpointPen => 'ic_pen_ballpoint',
      ToolType.fountainPen => 'ic_pen_fountain',
      ToolType.pencil => 'ic_pencil',
      ToolType.brush => 'ic_brush',
      ToolType.highlighter => 'ic_highlighter',
      ToolType.pixelEraser => 'ic_eraser_pixel',
      ToolType.strokeEraser => 'ic_eraser_stroke',
      ToolType.lassoEraser => 'ic_eraser_lasso',
      ToolType.laserPointer => 'ic_laser',
      ToolType.shapes => 'ic_shapes',
      ToolType.text => 'ic_text',
      ToolType.sticker => 'ic_sticker',
      ToolType.image => 'ic_image',
      ToolType.selection => 'ic_selection',
      ToolType.panZoom => 'ic_pan',
    };
  }
}
