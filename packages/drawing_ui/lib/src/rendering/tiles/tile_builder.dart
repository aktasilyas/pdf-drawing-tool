import 'dart:ui' as ui;

import 'package:drawing_ui/src/rendering/element_scene_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_rasterizer.dart';

/// Turns scene content into [CachedTile]s.
///
/// A plain tile is one src-over image. A blend tile (multiply/screen content)
/// is an opaque pair `A`, `K` with `result = A * page + K` per channel:
/// every op the renderer emits is affine over an opaque destination, so the
/// whole tile is. `K` is the content over black, `A` is (content over white)
/// minus `K`.
class TileBuilder {
  const TileBuilder(this._rasterizer);

  final TileRasterizer _rasterizer;

  static const ui.Color _black = ui.Color(0xFF000000);
  static const ui.Color _white = ui.Color(0xFFFFFFFF);

  /// Builds the tile at [rect] by painting [renderer] over [base] (the
  /// previous tile of the same grid, or null for a fresh one).
  ///
  /// With [blend] the result is a blend tile; a plain [base] is converted
  /// (`K` = base over black, white render = base over white).
  CachedTile build({
    required TileKey key,
    required ui.Rect rect,
    required double scale,
    required ElementSceneRenderer renderer,
    CachedTile? base,
    bool blend = false,
  }) {
    void paint(ui.Canvas canvas) => renderer.paintRegion(canvas, rect);
    final baseIsBlend = base?.isBlend ?? false;
    if (!blend && !baseIsBlend) {
      final image = _rasterizer.rasterize(
        pageRect: rect,
        scale: scale,
        base: base?.image,
        paint: paint,
      );
      return CachedTile(key, rect, image);
    }
    if (!blend) {
      // Normal content on top of a blend tile: one pass into its overlay.
      final overlay = _rasterizer.rasterize(
        pageRect: rect,
        scale: scale,
        base: base!.overlayImage,
        paint: paint,
      );
      return CachedTile(
        key,
        rect,
        base.image,
        multiplyImage: base.multiplyImage,
        overlayImage: overlay,
      );
    }

    // Blend content: rebuild the pair, folding in the old overlay.
    final oldA = base?.multiplyImage;
    final oldOverlay = base?.overlayImage;
    final k = _rasterizer.rasterize(
      pageRect: rect,
      scale: scale,
      background: oldA == null ? _black : null, // an opaque K covers it
      base: base?.image,
      layers: [
        if (oldOverlay != null) (oldOverlay, ui.BlendMode.srcOver),
      ],
      paint: paint,
    );
    // White render: ops over (A + K [+ overlay]) of a blend base, or over a
    // plain base.
    final white = _rasterizer.rasterize(
      pageRect: rect,
      scale: scale,
      background: oldA == null ? _white : null, // an opaque A covers it
      base: oldA ?? base?.image,
      layers: [
        if (oldA != null) (base!.image, ui.BlendMode.plus),
        if (oldOverlay != null) (oldOverlay, ui.BlendMode.srcOver),
      ],
      paint: paint,
    );
    final a = _rasterizer.rasterize(
      pageRect: rect,
      scale: scale,
      base: white,
      layers: [(k, ui.BlendMode.difference)],
      paint: (_) {},
    );
    white.dispose();
    return CachedTile(key, rect, k, multiplyImage: a);
  }
}
