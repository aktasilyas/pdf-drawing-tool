/// Enums used by [StrokeStyle] for pen nib, blend mode, pattern, and texture.

/// The shape of the pen nib/tip.
enum NibShape {
  /// A circular nib shape.
  circle,

  /// An elliptical nib shape.
  ellipse,

  /// A rectangular nib shape.
  rectangle,
}

/// Blend modes for drawing operations.
enum DrawingBlendMode {
  /// Normal blending (default).
  normal,

  /// Multiply blend mode.
  multiply,

  /// Screen blend mode.
  screen,

  /// Overlay blend mode.
  overlay,

  /// Darken blend mode.
  darken,

  /// Lighten blend mode.
  lighten,
}

/// Stroke pattern types for dashed lines.
enum StrokePattern {
  /// Solid continuous line.
  solid,

  /// Dashed line pattern.
  dashed,

  /// Dotted line pattern.
  dotted,
}

/// Texture types for stroke rendering.
enum StrokeTexture {
  /// No texture, smooth stroke.
  none,

  /// Pencil-like grainy texture.
  pencil,

  /// Chalk-like rough texture.
  chalk,

  /// Watercolor-like soft edges.
  watercolor,
}
