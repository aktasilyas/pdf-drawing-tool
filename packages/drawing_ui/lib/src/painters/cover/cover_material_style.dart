import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/cover/cover_texture_store.dart';

/// How a photographic tile is tinted onto a cover colour.
///
/// The tile is mid-grey detail. Its brighter half is drawn as a tinted
/// highlight and its darker half as a tinted shadow, both source-over, so the
/// grain reads on light and dark colours alike (plain overlay vanishes on
/// navy). One tile therefore serves every colour of a family.
class CoverMaterialStyle {
  const CoverMaterialStyle(this.tileWidthFraction, this.highlight, this.shadow);

  /// Tile width as a fraction of the cover width.
  final double tileWidthFraction;

  /// Highlight and shadow strength (alpha per unit of tile deviation).
  final double highlight;
  final double shadow;

  static const _styles = <CoverMaterial, CoverMaterialStyle>{
    CoverMaterial.leather: CoverMaterialStyle(0.85, 2.6, 3.2),
    CoverMaterial.linen: CoverMaterialStyle(0.42, 1.0, 1.15),
    CoverMaterial.kraft: CoverMaterialStyle(0.9, 1.8, 2.2),
    CoverMaterial.felt: CoverMaterialStyle(0.6, 0.7, 0.8),
  };

  static CoverMaterialStyle of(CoverMaterial m) => _styles[m]!;

  /// Paints for the highlight and shadow passes, or null if the tile for
  /// [material] is not loaded yet. [scale] multiplies both strengths.
  static List<ui.Paint>? paints(CoverMaterial material, ui.Color base,
      double coverWidth, ui.Color highlightTint, ui.Color shadowTint,
      {double scale = 1}) {
    final image = CoverTextureStore.imageFor(material);
    if (image == null) return null;
    final style = of(material);
    final s = coverWidth * style.tileWidthFraction / image.width;
    final matrix =
        Float64List.fromList([s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
    final shader = ui.ImageShader(
        image, ui.TileMode.repeated, ui.TileMode.repeated, matrix,
        filterQuality: ui.FilterQuality.medium);
    ui.ColorFilter filter(ui.Color tint, double k, double sign) =>
        ui.ColorFilter.matrix([
          0, 0, 0, 0, tint.r * 255, //
          0, 0, 0, 0, tint.g * 255,
          0, 0, 0, 0, tint.b * 255,
          sign * k * scale, 0, 0, 0, -sign * 0.5 * k * scale * 255,
        ]);
    return [
      ui.Paint()
        ..shader = shader
        ..colorFilter = filter(highlightTint, style.highlight, 1),
      ui.Paint()
        ..shader = shader
        ..colorFilter = filter(shadowTint, style.shadow, -1),
    ];
  }
}
