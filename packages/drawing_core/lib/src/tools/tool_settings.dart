import 'dart:ui' show Color;
import 'package:equatable/equatable.dart';

import '../models/nib_shape.dart';
import 'tool_type.dart';

/// Base class for all tool settings.
///
/// Each tool type has its own settings subclass with type-specific options.
sealed class ToolSettings extends Equatable {
  const ToolSettings();

  /// The tool type these settings apply to.
  ToolType get toolType;

  /// Converts these settings to a JSON-serializable map.
  Map<String, dynamic> toJson();

  /// Creates settings from a JSON map.
  factory ToolSettings.fromJson(Map<String, dynamic> json) {
    final type = ToolType.values.firstWhere(
      (t) => t.name == json['toolType'],
    );
    return switch (type) {
      ToolType.ballpointPen ||
      ToolType.fountainPen ||
      ToolType.pencil ||
      ToolType.brush =>
        PenSettings.fromJson(json),
      ToolType.highlighter => HighlighterSettings.fromJson(json),
      ToolType.pixelEraser ||
      ToolType.strokeEraser ||
      ToolType.lassoEraser =>
        EraserSettings.fromJson(json),
      ToolType.laserPointer => LaserPointerSettings.fromJson(json),
      ToolType.shapes => ShapeSettings.fromJson(json),
      ToolType.text => TextSettings.fromJson(json),
      _ => throw UnimplementedError('Settings not implemented for $type'),
    };
  }
}

/// Settings for pen-type tools (ballpoint, fountain, pencil, brush).
class PenSettings extends ToolSettings {
  const PenSettings({
    required this.toolType,
    required this.color,
    required this.thickness,
    this.stabilization = 0.0,
    this.pressureSensitivity = 1.0,
    this.nibShape,
  }) : assert(
          toolType == ToolType.ballpointPen ||
              toolType == ToolType.fountainPen ||
              toolType == ToolType.pencil ||
              toolType == ToolType.brush,
        );

  /// Creates default settings for a ballpoint pen.
  factory PenSettings.ballpoint({
    Color color = const Color(0xFF000000),
    double thickness = 2.0,
    double stabilization = 0.0,
  }) {
    return PenSettings(
      toolType: ToolType.ballpointPen,
      color: color,
      thickness: thickness,
      stabilization: stabilization,
      nibShape: CircleNib(radius: thickness / 2),
    );
  }

  /// Creates default settings for a fountain pen.
  factory PenSettings.fountain({
    Color color = const Color(0xFF000000),
    double thickness = 3.0,
    double nibAngle = 0.5,
    double stabilization = 0.0,
  }) {
    return PenSettings(
      toolType: ToolType.fountainPen,
      color: color,
      thickness: thickness,
      stabilization: stabilization,
      nibShape: EllipseNib(
        width: thickness,
        height: thickness * 0.3,
        angle: nibAngle,
      ),
    );
  }

  /// Creates default settings for a pencil.
  factory PenSettings.pencil({
    Color color = const Color(0xFF333333),
    double thickness = 1.5,
  }) {
    return PenSettings(
      toolType: ToolType.pencil,
      color: color,
      thickness: thickness,
      pressureSensitivity: 0.7,
      nibShape: CircleNib(radius: thickness / 2),
    );
  }

  /// Creates default settings for a brush.
  factory PenSettings.brush({
    Color color = const Color(0xFF000000),
    double thickness = 8.0,
  }) {
    return PenSettings(
      toolType: ToolType.brush,
      color: color,
      thickness: thickness,
      pressureSensitivity: 1.5,
      nibShape: CircleNib(radius: thickness / 2),
    );
  }

  @override
  final ToolType toolType;

  /// The stroke color.
  final Color color;

  /// The stroke thickness in logical pixels.
  final double thickness;

  /// The amount of stroke stabilization (smoothing).
  ///
  /// Range: 0.0 (none) to 1.0 (maximum).
  final double stabilization;

  /// How much pressure affects stroke width.
  ///
  /// Range: 0.0 (none) to 2.0+ (amplified).
  final double pressureSensitivity;

  /// The geometric shape of the nib.
  ///
  /// If null, defaults based on [toolType].
  final NibShape? nibShape;

  /// Returns the effective nib shape.
  NibShape get effectiveNibShape {
    if (nibShape != null) return nibShape!;
    return switch (toolType) {
      ToolType.fountainPen => EllipseNib(
          width: thickness,
          height: thickness * 0.3,
          angle: 0.5,
        ),
      _ => CircleNib(radius: thickness / 2),
    };
  }

  PenSettings copyWith({
    ToolType? toolType,
    Color? color,
    double? thickness,
    double? stabilization,
    double? pressureSensitivity,
    NibShape? nibShape,
  }) {
    return PenSettings(
      toolType: toolType ?? this.toolType,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      stabilization: stabilization ?? this.stabilization,
      pressureSensitivity: pressureSensitivity ?? this.pressureSensitivity,
      nibShape: nibShape ?? this.nibShape,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'toolType': toolType.name,
        'color': color.value,
        'thickness': thickness,
        'stabilization': stabilization,
        'pressureSensitivity': pressureSensitivity,
        if (nibShape != null) 'nibShape': nibShape!.toJson(),
      };

  factory PenSettings.fromJson(Map<String, dynamic> json) {
    return PenSettings(
      toolType: ToolType.values.firstWhere((t) => t.name == json['toolType']),
      color: Color(json['color'] as int),
      thickness: (json['thickness'] as num).toDouble(),
      stabilization: (json['stabilization'] as num?)?.toDouble() ?? 0.0,
      pressureSensitivity:
          (json['pressureSensitivity'] as num?)?.toDouble() ?? 1.0,
      nibShape: json['nibShape'] != null
          ? NibShape.fromJson(json['nibShape'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [toolType, color, thickness, stabilization, pressureSensitivity, nibShape];
}

/// Settings for the highlighter tool.
class HighlighterSettings extends ToolSettings {
  const HighlighterSettings({
    this.color = const Color(0xFFFFEB3B),
    this.thickness = 20.0,
    this.opacity = 0.4,
    this.straightLineMode = false,
  });

  @override
  ToolType get toolType => ToolType.highlighter;

  /// The highlight color.
  final Color color;

  /// The highlight thickness in logical pixels.
  final double thickness;

  /// The opacity of the highlight.
  final double opacity;

  /// Whether to constrain to straight lines.
  final bool straightLineMode;

  HighlighterSettings copyWith({
    Color? color,
    double? thickness,
    double? opacity,
    bool? straightLineMode,
  }) {
    return HighlighterSettings(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      opacity: opacity ?? this.opacity,
      straightLineMode: straightLineMode ?? this.straightLineMode,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'toolType': toolType.name,
        'color': color.value,
        'thickness': thickness,
        'opacity': opacity,
        'straightLineMode': straightLineMode,
      };

  factory HighlighterSettings.fromJson(Map<String, dynamic> json) {
    return HighlighterSettings(
      color: Color(json['color'] as int),
      thickness: (json['thickness'] as num).toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.4,
      straightLineMode: json['straightLineMode'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [color, thickness, opacity, straightLineMode];
}

/// Eraser mode variants.
enum EraserMode {
  /// Erases individual pixels.
  pixel,

  /// Erases entire strokes on contact.
  stroke,

  /// Erases strokes within a lasso selection.
  lasso,
}

/// Settings for eraser tools.
class EraserSettings extends ToolSettings {
  const EraserSettings({
    this.mode = EraserMode.pixel,
    this.size = 20.0,
    this.pressureSensitive = false,
    this.eraseOnlyHighlighter = false,
    this.eraseBandOnly = false,
    this.autoLift = false,
  });

  @override
  ToolType get toolType => switch (mode) {
        EraserMode.pixel => ToolType.pixelEraser,
        EraserMode.stroke => ToolType.strokeEraser,
        EraserMode.lasso => ToolType.lassoEraser,
      };

  /// The eraser mode.
  final EraserMode mode;

  /// The eraser size in logical pixels.
  final double size;

  /// Whether eraser size varies with pressure.
  final bool pressureSensitive;

  /// Whether to erase only highlighter strokes.
  final bool eraseOnlyHighlighter;

  /// Whether to erase only within a horizontal band.
  final bool eraseBandOnly;

  /// Whether to automatically lift after erasing.
  final bool autoLift;

  EraserSettings copyWith({
    EraserMode? mode,
    double? size,
    bool? pressureSensitive,
    bool? eraseOnlyHighlighter,
    bool? eraseBandOnly,
    bool? autoLift,
  }) {
    return EraserSettings(
      mode: mode ?? this.mode,
      size: size ?? this.size,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      eraseOnlyHighlighter: eraseOnlyHighlighter ?? this.eraseOnlyHighlighter,
      eraseBandOnly: eraseBandOnly ?? this.eraseBandOnly,
      autoLift: autoLift ?? this.autoLift,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'toolType': toolType.name,
        'mode': mode.name,
        'size': size,
        'pressureSensitive': pressureSensitive,
        'eraseOnlyHighlighter': eraseOnlyHighlighter,
        'eraseBandOnly': eraseBandOnly,
        'autoLift': autoLift,
      };

  factory EraserSettings.fromJson(Map<String, dynamic> json) {
    return EraserSettings(
      mode: EraserMode.values.firstWhere((m) => m.name == json['mode']),
      size: (json['size'] as num).toDouble(),
      pressureSensitive: json['pressureSensitive'] as bool? ?? false,
      eraseOnlyHighlighter: json['eraseOnlyHighlighter'] as bool? ?? false,
      eraseBandOnly: json['eraseBandOnly'] as bool? ?? false,
      autoLift: json['autoLift'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        size,
        pressureSensitive,
        eraseOnlyHighlighter,
        eraseBandOnly,
        autoLift,
      ];
}

/// Laser pointer display mode.
enum LaserMode {
  /// Shows as a dot that follows the pointer.
  dot,

  /// Shows as a line trail.
  line,
}

/// Settings for the laser pointer tool.
class LaserPointerSettings extends ToolSettings {
  const LaserPointerSettings({
    this.color = const Color(0xFFFF0000),
    this.mode = LaserMode.dot,
    this.thickness = 4.0,
    this.duration = const Duration(seconds: 3),
  });

  @override
  ToolType get toolType => ToolType.laserPointer;

  /// The laser color.
  final Color color;

  /// The display mode.
  final LaserMode mode;

  /// The laser thickness.
  final double thickness;

  /// How long the laser trail persists.
  final Duration duration;

  LaserPointerSettings copyWith({
    Color? color,
    LaserMode? mode,
    double? thickness,
    Duration? duration,
  }) {
    return LaserPointerSettings(
      color: color ?? this.color,
      mode: mode ?? this.mode,
      thickness: thickness ?? this.thickness,
      duration: duration ?? this.duration,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'toolType': toolType.name,
        'color': color.value,
        'mode': mode.name,
        'thickness': thickness,
        'durationMs': duration.inMilliseconds,
      };

  factory LaserPointerSettings.fromJson(Map<String, dynamic> json) {
    return LaserPointerSettings(
      color: Color(json['color'] as int),
      mode: LaserMode.values.firstWhere((m) => m.name == json['mode']),
      thickness: (json['thickness'] as num).toDouble(),
      duration: Duration(milliseconds: json['durationMs'] as int),
    );
  }

  @override
  List<Object?> get props => [color, mode, thickness, duration];
}

/// Available shape types.
enum ShapeType {
  line,
  arrow,
  rectangle,
  roundedRectangle,
  ellipse,
  triangle,
  star,
  polygon,
}

/// Settings for the shapes tool.
class ShapeSettings extends ToolSettings {
  const ShapeSettings({
    this.shapeType = ShapeType.rectangle,
    this.strokeColor = const Color(0xFF000000),
    this.fillColor,
    this.strokeThickness = 2.0,
    this.filled = false,
  });

  @override
  ToolType get toolType => ToolType.shapes;

  /// The type of shape to draw.
  final ShapeType shapeType;

  /// The stroke color.
  final Color strokeColor;

  /// The fill color (if [filled] is true).
  final Color? fillColor;

  /// The stroke thickness.
  final double strokeThickness;

  /// Whether the shape is filled.
  final bool filled;

  ShapeSettings copyWith({
    ShapeType? shapeType,
    Color? strokeColor,
    Color? fillColor,
    double? strokeThickness,
    bool? filled,
  }) {
    return ShapeSettings(
      shapeType: shapeType ?? this.shapeType,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      strokeThickness: strokeThickness ?? this.strokeThickness,
      filled: filled ?? this.filled,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'toolType': toolType.name,
        'shapeType': shapeType.name,
        'strokeColor': strokeColor.value,
        if (fillColor != null) 'fillColor': fillColor!.value,
        'strokeThickness': strokeThickness,
        'filled': filled,
      };

  factory ShapeSettings.fromJson(Map<String, dynamic> json) {
    return ShapeSettings(
      shapeType:
          ShapeType.values.firstWhere((s) => s.name == json['shapeType']),
      strokeColor: Color(json['strokeColor'] as int),
      fillColor:
          json['fillColor'] != null ? Color(json['fillColor'] as int) : null,
      strokeThickness: (json['strokeThickness'] as num).toDouble(),
      filled: json['filled'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [shapeType, strokeColor, fillColor, strokeThickness, filled];
}

/// Settings for the text tool.
class TextSettings extends ToolSettings {
  const TextSettings({
    this.color = const Color(0xFF000000),
    this.fontSize = 16.0,
    this.fontFamily,
    this.bold = false,
    this.italic = false,
  });

  @override
  ToolType get toolType => ToolType.text;

  /// The text color.
  final Color color;

  /// The font size in logical pixels.
  final double fontSize;

  /// The font family name.
  final String? fontFamily;

  /// Whether the text is bold.
  final bool bold;

  /// Whether the text is italic.
  final bool italic;

  TextSettings copyWith({
    Color? color,
    double? fontSize,
    String? fontFamily,
    bool? bold,
    bool? italic,
  }) {
    return TextSettings(
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'toolType': toolType.name,
        'color': color.value,
        'fontSize': fontSize,
        if (fontFamily != null) 'fontFamily': fontFamily,
        'bold': bold,
        'italic': italic,
      };

  factory TextSettings.fromJson(Map<String, dynamic> json) {
    return TextSettings(
      color: Color(json['color'] as int),
      fontSize: (json['fontSize'] as num).toDouble(),
      fontFamily: json['fontFamily'] as String?,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [color, fontSize, fontFamily, bold, italic];
}
