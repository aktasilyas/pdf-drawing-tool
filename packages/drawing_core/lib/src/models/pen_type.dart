import 'package:drawing_core/src/models/stroke_style.dart';

/// Defines all available pen types with their characteristics.
enum PenType {
  /// Matte pencil with slight texture.
  pencil,

  /// Hard pencil for sketching, lighter tones.
  hardPencil,

  /// Classic ballpoint pen, clean lines.
  ballpointPen,

  /// Gel pen, smooth and vibrant colors.
  gelPen,

  /// Dashed pen for diagrams and emphasis.
  dashedPen,

  /// Semi-transparent highlighter.
  highlighter,

  /// Pressure-sensitive brush pen.
  brushPen,

  /// Neon highlighter with glow effect.
  neonHighlighter,

  /// Ruler pen for drawing straight lines.
  rulerPen,
}

/// Configuration for each pen type.
class PenTypeConfig {
  /// English display name.
  final String displayName;

  /// Turkish display name.
  final String displayNameTr;

  /// Default thickness for this pen type.
  final double defaultThickness;

  /// Minimum allowed thickness.
  final double minThickness;

  /// Maximum allowed thickness.
  final double maxThickness;

  /// Default opacity (0.0 to 1.0).
  final double defaultOpacity;

  /// Shape of the pen nib.
  final NibShape nibShape;

  /// Stroke pattern (solid, dashed, dotted).
  final StrokePattern pattern;

  /// Texture effect.
  final StrokeTexture texture;

  /// Glow radius for neon effects.
  final double glowRadius;

  /// Glow intensity (0.0 to 1.0).
  final double glowIntensity;

  /// Dash pattern [dash length, gap length].
  final List<double>? dashPattern;

  /// Nib angle in degrees for calligraphy (0 = horizontal, 90 = vertical).
  final double nibAngle;

  /// Whether this pen type supports pressure-sensitive variable width.
  final bool pressureSensitive;

  const PenTypeConfig({
    required this.displayName,
    required this.displayNameTr,
    required this.defaultThickness,
    this.minThickness = 0.1,
    this.maxThickness = 20.0,
    this.defaultOpacity = 1.0,
    this.nibShape = NibShape.circle,
    this.pattern = StrokePattern.solid,
    this.texture = StrokeTexture.none,
    this.glowRadius = 0.0,
    this.glowIntensity = 0.0,
    this.dashPattern,
    this.nibAngle = 0.0,
    this.pressureSensitive = false,
  });
}

/// Extension to get configuration for each pen type.
extension PenTypeExtension on PenType {
  /// Gets the configuration for this pen type.
  PenTypeConfig get config {
    switch (this) {
      case PenType.pencil:
        return const PenTypeConfig(
          displayName: 'Pencil',
          displayNameTr: 'Kurşun Kalem',
          defaultThickness: 1.5,
          maxThickness: 8.0,
          texture: StrokeTexture.pencil,
        );
      case PenType.hardPencil:
        return const PenTypeConfig(
          displayName: 'Hard Pencil',
          displayNameTr: 'Sert Kalem',
          defaultThickness: 1.0,
          maxThickness: 5.0,
          defaultOpacity: 0.7,
          texture: StrokeTexture.pencil,
        );
      case PenType.ballpointPen:
        return const PenTypeConfig(
          displayName: 'Ballpoint Pen',
          displayNameTr: 'Tükenmez Kalem',
          defaultThickness: 1.5,
          maxThickness: 5.0,
        );
      case PenType.gelPen:
        return const PenTypeConfig(
          displayName: 'Gel Pen',
          displayNameTr: 'Jel Kalem',
          defaultThickness: 2.0,
          maxThickness: 8.0,
        );
      case PenType.dashedPen:
        return const PenTypeConfig(
          displayName: 'Dashed Pen',
          displayNameTr: 'Kesik Çizgi',
          defaultThickness: 2.0,
          maxThickness: 8.0,
          pattern: StrokePattern.dashed,
          dashPattern: [8.0, 4.0],
        );
      case PenType.highlighter:
        return const PenTypeConfig(
          displayName: 'Highlighter',
          displayNameTr: 'Fosforlu Kalem',
          defaultThickness: 20.0,
          minThickness: 10.0,
          maxThickness: 40.0,
          defaultOpacity: 0.4,
          nibShape: NibShape.rectangle,
        );
      case PenType.brushPen:
        return const PenTypeConfig(
          displayName: 'Brush Pen',
          displayNameTr: 'Fırça Kalem',
          defaultThickness: 5.0,
          maxThickness: 30.0,
          nibShape: NibShape.ellipse,
          pressureSensitive: true,
        );
      case PenType.neonHighlighter:
        return const PenTypeConfig(
          displayName: 'Neon Highlighter',
          displayNameTr: 'Neon Fosforlu',
          defaultThickness: 15.0,
          minThickness: 8.0,
          maxThickness: 30.0,
          defaultOpacity: 0.8,
          glowRadius: 8.0,
          glowIntensity: 0.6,
          nibShape: NibShape.rectangle,
        );
      case PenType.rulerPen:
        return const PenTypeConfig(
          displayName: 'Ruler Pen',
          displayNameTr: 'Cetvelli Kalem',
          defaultThickness: 2.0,
          minThickness: 0.5,
          maxThickness: 10.0,
          nibShape: NibShape.circle,
        );
    }
  }

  /// Creates a StrokeStyle from this pen type with given color.
  ///
  /// [pressureSensitive] and [pressureSensitivity] override the pen type
  /// defaults when provided (e.g. from user settings).
  StrokeStyle toStrokeStyle({
    required int color,
    double? thickness,
    bool? pressureSensitive,
    double? pressureSensitivity,
  }) {
    final c = config;
    return StrokeStyle(
      color: color,
      thickness: thickness ?? c.defaultThickness,
      opacity: c.defaultOpacity,
      nibShape: c.nibShape,
      pattern: c.pattern,
      texture: c.texture,
      glowRadius: c.glowRadius,
      glowIntensity: c.glowIntensity,
      dashPattern: c.dashPattern,
      nibAngle: c.nibAngle,
      pressureSensitive: pressureSensitive ?? c.pressureSensitive,
      pressureSensitivity: pressureSensitivity ?? 0.75,
    );
  }
}
