import 'package:equatable/equatable.dart';

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

/// Defines the visual style of a stroke.
///
/// Contains color, thickness, opacity, nib shape, blend mode, and eraser flag.
/// Colors are represented as ARGB integers (0xAARRGGBB format).
///
/// This class is immutable and uses [Equatable] for value equality.
class StrokeStyle extends Equatable {
  /// The color of the stroke in ARGB format (0xAARRGGBB).
  final int color;

  /// The thickness of the stroke (0.1 to 50.0).
  final double thickness;

  /// The opacity of the stroke (0.0 to 1.0).
  final double opacity;

  /// The shape of the pen nib.
  final NibShape nibShape;

  /// The blend mode for the stroke.
  final DrawingBlendMode blendMode;

  /// Whether this style is for an eraser tool.
  final bool isEraser;

  /// Creates a new [StrokeStyle].
  ///
  /// [color] is in ARGB format (0xAARRGGBB).
  /// [thickness] is clamped to the range [0.1, 50.0].
  /// [opacity] is clamped to the range [0.0, 1.0].
  StrokeStyle({
    required this.color,
    required double thickness,
    double opacity = 1.0,
    this.nibShape = NibShape.circle,
    this.blendMode = DrawingBlendMode.normal,
    this.isEraser = false,
  })  : thickness = thickness.clamp(0.1, 50.0),
        opacity = opacity.clamp(0.0, 1.0);

  /// Creates a pen style.
  ///
  /// Default: black color, 2.0 thickness, circle nib.
  factory StrokeStyle.pen({
    int color = 0xFF000000,
    double thickness = 2.0,
  }) {
    return StrokeStyle(
      color: color,
      thickness: thickness,
      nibShape: NibShape.circle,
    );
  }

  /// Creates a highlighter style.
  ///
  /// Default: yellow color, 20.0 thickness, rectangle nib, 0.5 opacity.
  factory StrokeStyle.highlighter({
    int color = 0xFFFFEB3B,
    double thickness = 20.0,
  }) {
    return StrokeStyle(
      color: color,
      thickness: thickness,
      opacity: 0.5,
      nibShape: NibShape.rectangle,
    );
  }

  /// Creates a brush style.
  ///
  /// Default: black color, 5.0 thickness, ellipse nib.
  factory StrokeStyle.brush({
    int color = 0xFF000000,
    double thickness = 5.0,
  }) {
    return StrokeStyle(
      color: color,
      thickness: thickness,
      nibShape: NibShape.ellipse,
    );
  }

  /// Creates an eraser style.
  ///
  /// Default: white color, 10.0 thickness, isEraser true.
  factory StrokeStyle.eraser({
    double thickness = 10.0,
  }) {
    return StrokeStyle(
      color: 0xFFFFFFFF,
      thickness: thickness,
      isEraser: true,
    );
  }

  /// Returns the alpha component of the color (0-255).
  int getAlpha() => (color >> 24) & 0xFF;

  /// Returns the red component of the color (0-255).
  int getRed() => (color >> 16) & 0xFF;

  /// Returns the green component of the color (0-255).
  int getGreen() => (color >> 8) & 0xFF;

  /// Returns the blue component of the color (0-255).
  int getBlue() => color & 0xFF;

  /// Creates a copy of this [StrokeStyle] with the given fields replaced.
  StrokeStyle copyWith({
    int? color,
    double? thickness,
    double? opacity,
    NibShape? nibShape,
    DrawingBlendMode? blendMode,
    bool? isEraser,
  }) {
    return StrokeStyle(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      opacity: opacity ?? this.opacity,
      nibShape: nibShape ?? this.nibShape,
      blendMode: blendMode ?? this.blendMode,
      isEraser: isEraser ?? this.isEraser,
    );
  }

  /// Converts this [StrokeStyle] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'thickness': thickness,
      'opacity': opacity,
      'nibShape': nibShape.name,
      'blendMode': blendMode.name,
      'isEraser': isEraser,
    };
  }

  /// Creates a [StrokeStyle] from a JSON map.
  factory StrokeStyle.fromJson(Map<String, dynamic> json) {
    return StrokeStyle(
      color: json['color'] as int,
      thickness: (json['thickness'] as num).toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      nibShape: NibShape.values.firstWhere(
        (e) => e.name == json['nibShape'],
        orElse: () => NibShape.circle,
      ),
      blendMode: DrawingBlendMode.values.firstWhere(
        (e) => e.name == json['blendMode'],
        orElse: () => DrawingBlendMode.normal,
      ),
      isEraser: json['isEraser'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        color,
        thickness,
        opacity,
        nibShape,
        blendMode,
        isEraser,
      ];

  @override
  String toString() {
    return 'StrokeStyle(color: 0x${color.toRadixString(16).padLeft(8, '0').toUpperCase()}, '
        'thickness: $thickness, opacity: $opacity, nibShape: $nibShape, '
        'blendMode: $blendMode, isEraser: $isEraser)';
  }
}
