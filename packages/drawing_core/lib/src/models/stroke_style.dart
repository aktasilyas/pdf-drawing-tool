import 'package:equatable/equatable.dart';

import 'stroke_style_enums.dart';
export 'stroke_style_enums.dart';

/// Defines the visual style of a stroke.
///
/// Contains color, thickness, opacity, nib shape, blend mode, eraser flag,
/// pattern, texture, glow effects, and pressure sensitivity settings.
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

  /// The pattern of the stroke (solid, dashed, dotted).
  final StrokePattern pattern;

  /// The texture of the stroke.
  final StrokeTexture texture;

  /// Glow radius for neon effects (0 = no glow, max 20.0).
  final double glowRadius;

  /// Glow intensity (0.0 to 1.0).
  final double glowIntensity;

  /// Dash pattern [dash length, gap length]. Null for solid.
  final List<double>? dashPattern;

  /// Nib angle in degrees (for calligraphy ellipse nib). 0 = horizontal, 90 = vertical.
  final double nibAngle;

  /// Whether this stroke uses pressure-sensitive variable width rendering.
  final bool pressureSensitive;

  /// How much pressure affects width (0.0 = uniform, 1.0 = full range).
  /// Clamped to [0.0, 1.0].
  final double pressureSensitivity;

  /// Creates a new [StrokeStyle].
  ///
  /// [color] is in ARGB format (0xAARRGGBB).
  /// [thickness] is clamped to the range [0.1, 50.0].
  /// [opacity] is clamped to the range [0.0, 1.0].
  /// [glowRadius] is clamped to the range [0.0, 20.0].
  /// [glowIntensity] is clamped to the range [0.0, 1.0].
  /// [nibAngle] is the angle in degrees for ellipse nib (calligraphy).
  /// [pressureSensitivity] is clamped to [0.0, 1.0].
  StrokeStyle({
    required this.color,
    required double thickness,
    double opacity = 1.0,
    this.nibShape = NibShape.circle,
    this.blendMode = DrawingBlendMode.normal,
    this.isEraser = false,
    this.pattern = StrokePattern.solid,
    this.texture = StrokeTexture.none,
    double glowRadius = 0.0,
    double glowIntensity = 0.0,
    this.dashPattern,
    this.nibAngle = 0.0,
    this.pressureSensitive = false,
    double pressureSensitivity = 0.75,
  })  : thickness = thickness.clamp(0.1, 50.0),
        opacity = opacity.clamp(0.0, 1.0),
        glowRadius = glowRadius.clamp(0.0, 20.0),
        glowIntensity = glowIntensity.clamp(0.0, 1.0),
        pressureSensitivity = pressureSensitivity.clamp(0.0, 1.0);

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

  /// Creates a brush style with pressure sensitivity enabled.
  ///
  /// Default: black color, 5.0 thickness, ellipse nib, pressure sensitive.
  factory StrokeStyle.brush({
    int color = 0xFF000000,
    double thickness = 5.0,
    bool pressureSensitive = true,
    double pressureSensitivity = 0.75,
  }) {
    return StrokeStyle(
      color: color,
      thickness: thickness,
      nibShape: NibShape.ellipse,
      pressureSensitive: pressureSensitive,
      pressureSensitivity: pressureSensitivity,
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
    StrokePattern? pattern,
    StrokeTexture? texture,
    double? glowRadius,
    double? glowIntensity,
    List<double>? dashPattern,
    double? nibAngle,
    bool? pressureSensitive,
    double? pressureSensitivity,
  }) {
    return StrokeStyle(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      opacity: opacity ?? this.opacity,
      nibShape: nibShape ?? this.nibShape,
      blendMode: blendMode ?? this.blendMode,
      isEraser: isEraser ?? this.isEraser,
      pattern: pattern ?? this.pattern,
      texture: texture ?? this.texture,
      glowRadius: glowRadius ?? this.glowRadius,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      dashPattern: dashPattern ?? this.dashPattern,
      nibAngle: nibAngle ?? this.nibAngle,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      pressureSensitivity: pressureSensitivity ?? this.pressureSensitivity,
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
      'pattern': pattern.name,
      'texture': texture.name,
      'glowRadius': glowRadius,
      'glowIntensity': glowIntensity,
      'dashPattern': dashPattern,
      'nibAngle': nibAngle,
      'pressureSensitive': pressureSensitive,
      'pressureSensitivity': pressureSensitivity,
    };
  }

  /// Creates a [StrokeStyle] from a JSON map.
  factory StrokeStyle.fromJson(Map<String, dynamic> json) {
    return StrokeStyle(
      color: _parseInt(json['color'], 0xFF000000),
      thickness: _parseDouble(json['thickness'], 1.0),
      opacity: _parseDouble(json['opacity'], 1.0),
      nibShape: NibShape.values.firstWhere(
        (e) => e.name == json['nibShape'],
        orElse: () => NibShape.circle,
      ),
      blendMode: DrawingBlendMode.values.firstWhere(
        (e) => e.name == json['blendMode'],
        orElse: () => DrawingBlendMode.normal,
      ),
      isEraser: json['isEraser'] as bool? ?? false,
      pattern: StrokePattern.values.firstWhere(
        (e) => e.name == json['pattern'],
        orElse: () => StrokePattern.solid,
      ),
      texture: StrokeTexture.values.firstWhere(
        (e) => e.name == json['texture'],
        orElse: () => StrokeTexture.none,
      ),
      glowRadius: _parseDouble(json['glowRadius'], 0.0),
      glowIntensity: _parseDouble(json['glowIntensity'], 0.0),
      dashPattern: (json['dashPattern'] as List<dynamic>?)
          ?.map((e) => _parseDouble(e, 0.0))
          .toList(),
      nibAngle: _parseDouble(json['nibAngle'], 0.0),
      pressureSensitive: json['pressureSensitive'] as bool? ?? false,
      pressureSensitivity: _parseDouble(json['pressureSensitivity'], 0.75),
    );
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is num) return value.toInt();
    return defaultValue;
  }

  @override
  List<Object?> get props => [
        color,
        thickness,
        opacity,
        nibShape,
        blendMode,
        isEraser,
        pattern,
        texture,
        glowRadius,
        glowIntensity,
        dashPattern,
        nibAngle,
        pressureSensitive,
        pressureSensitivity,
      ];

  @override
  String toString() {
    return 'StrokeStyle(color: 0x${color.toRadixString(16).padLeft(8, '0').toUpperCase()}, '
        'thickness: $thickness, opacity: $opacity, nibShape: $nibShape, '
        'blendMode: $blendMode, isEraser: $isEraser, pattern: $pattern, '
        'texture: $texture, glowRadius: $glowRadius, glowIntensity: $glowIntensity, '
        'pressureSensitive: $pressureSensitive, pressureSensitivity: $pressureSensitivity)';
  }
}
