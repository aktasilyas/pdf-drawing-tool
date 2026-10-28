import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/element_scene.dart';
import 'package:drawing_ui/src/rendering/tiles/scene_renderer_factory.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_builder.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_store.dart';

/// Composites the elements [ids] (appended on top of [scene]) onto the
/// existing tiles of [store].
///
/// Tiles that must stay vectors are moved in [store]; every rebuilt tile is
/// returned with the number of elements recorded into it, for the caller to
/// put into the store.
List<(CachedTile, int)> compositeAppended({
  required ElementScene scene,
  required TileGrid grid,
  required List<String> ids,
  required TileStore store,
  required TileBuilder builder,
  required FlutterStrokeRenderer strokeRenderer,
  required ImageCacheManager cacheManager,
}) {
  final appended = [for (final id in ids) scene.byId[id]!];
  final sub = buildSceneRenderer(
    subScene(scene, appended, ids),
    strokeRenderer,
    cacheManager,
  );

  final keys = <TileKey>{
    for (final e in appended) ...grid.keysIn(e.bounds),
  };
  final built = <(CachedTile, int)>[];
  for (final key in keys) {
    if (store.vector.contains(key)) continue;
    final tile = store.tiles[key];
    if (tile == null && !store.has(key)) continue; // built later
    final rect = grid.rectOf(key);
    final hits = appended.where((e) => e.bounds.overlaps(rect)).toList();
    if (hits.isEmpty) continue;
    if (hits.any((e) => e.isVectorOnly)) {
      store.drop(key);
      store.vector.add(key);
      continue;
    }
    built.add((
      builder.build(
        key: key,
        rect: rect,
        scale: grid.scale,
        renderer: sub,
        base: tile,
      ),
      hits.length,
    ));
  }
  return built;
}
