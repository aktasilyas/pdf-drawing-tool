import 'dart:ui' as ui;

import 'package:drawing_ui/src/rendering/element_scene_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_rasterizer.dart';

/// Turns scene content into [CachedTile]s.
///
/// Every tile is one transparent RGBA image, painted with the same element
/// order and blend modes as the vector path. The layer is transparent, so
/// multiply over empty pixels is normal alpha (see #115).
class TileBuilder {
  const TileBuilder(this._rasterizer);

  final TileRasterizer _rasterizer;

  /// Builds the tile at [rect] by painting [renderer] over [base] (the
  /// previous tile of the same grid, or null for a fresh one).
  CachedTile build({
    required TileKey key,
    required ui.Rect rect,
    required double scale,
    required ElementSceneRenderer renderer,
    CachedTile? base,
  }) {
    final image = _rasterizer.rasterize(
      pageRect: rect,
      scale: scale,
      base: base?.image,
      paint: (canvas) => renderer.paintRegion(canvas, rect),
    );
    return CachedTile(key, rect, image);
  }
}
