import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/element_scene.dart';
import 'package:drawing_ui/src/rendering/tiles/scene_diff.dart';
import 'package:drawing_ui/src/rendering/tiles/scene_renderer_factory.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_builder.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_rasterizer.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_store.dart';

/// Raster cache of the committed content of one (page, layer).
///
/// Owns every [ui.Image] it holds. Only visible tiles are kept fresh; dirty
/// off-screen tiles are dropped and rebuilt when they scroll into view.
///
/// On a scale change the old tiles stay as [legacyTiles] and the new visible
/// tiles become pending; a `TileRasterScheduler` fills them via
/// [rasterizeNextPending]. Multiply/screen content is cached as an image pair
/// (see `TileBuilder`); tiles with overlay/darken/lighten content are never
/// rasterized (see [vectorRects]).
class PageTileCache extends ChangeNotifier {
  PageTileCache({
    required FlutterStrokeRenderer strokeRenderer,
    required ImageCacheManager cacheManager,
    this.budgetBytes = 64 << 20,
    TileRasterizer rasterizer = const TileRasterizer(),
  })  : _strokeRenderer = strokeRenderer,
        _cacheManager = cacheManager,
        _rasterizer = rasterizer,
        _builder = TileBuilder(rasterizer);

  final FlutterStrokeRenderer _strokeRenderer;
  final ImageCacheManager _cacheManager;
  final TileRasterizer _rasterizer;
  final TileBuilder _builder;
  final int budgetBytes;

  final TileStore _store = TileStore();

  /// Visible tiles with content that wait for the scheduler.
  final List<TileKey> _pending = [];
  List<ui.Rect> _pendingRects = const [];
  List<ui.Rect> _vectorRects = const [];

  /// Tiles of the previous scale, drawn until the new ones are ready.
  List<CachedTile> _legacy = const [];
  ElementScene? _scene;
  TileGrid? _grid;
  ui.Rect _viewport = ui.Rect.zero;
  int _clock = 0;
  List<CachedTile> _visible = const [];

  int _rasterCount = 0;
  int _lastRecorded = 0;
  List<TileKey> _lastKeys = const [];

  /// Tiles with content that intersect the viewport. Painters iterate only.
  Iterable<CachedTile> get visibleTiles => _visible;

  /// Old-scale tiles still shown while [hasPending].
  List<CachedTile> get legacyTiles => _legacy;

  /// Page rects of visible tiles not rasterized yet.
  List<ui.Rect> get pendingRects => _pendingRects;

  /// Page rects of visible tiles drawn as vectors (overlay/darken/lighten).
  List<ui.Rect> get vectorRects => _vectorRects;

  /// Whether visible tiles at the current scale still wait to be rasterized.
  bool get hasPending => _pending.isNotEmpty;
  int get pendingCount => _pending.length;

  /// Total tile rasterizations since creation.
  @visibleForTesting
  int get debugRasterCount => _rasterCount;

  /// Most elements recorded into one tile by the last call that changed pixels.
  @visibleForTesting
  int get debugLastRecordedElements => _lastRecorded;

  /// Tiles rasterized by the last call that changed pixels.
  @visibleForTesting
  List<TileKey> get debugRasterizedKeys => _lastKeys;

  @visibleForTesting
  List<TileKey> get debugPendingKeys => List.of(_pending);
  @visibleForTesting
  void debugDropLegacy() => _releaseLegacy();

  int get cachedBytes => _store.bytes;

  /// Paints [rect] of the current scene as vectors (cold/blend tiles).
  void paintVectorRegion(ui.Canvas canvas, ui.Rect rect) {
    final scene = _scene;
    if (scene == null) return;
    buildSceneRenderer(scene, _strokeRenderer, _cacheManager)
        .paintRegion(canvas, rect);
  }

  /// Sets the visible page rect and the raster scale (zoom * pixel ratio).
  ///
  /// While [interacting] nothing is rasterized. On settle at a new scale the
  /// old tiles become [legacyTiles] and new visible tiles become pending (or
  /// are rasterized right away when there is nothing to fall back to).
  void setViewport(
    ui.Rect visiblePageRect,
    double targetScale, {
    required bool interacting,
  }) {
    _viewport = visiblePageRect;
    if (interacting) {
      _finish();
      return;
    }
    final grid = _grid;
    if (grid == null || !grid.hasScale(targetScale)) {
      _retireTiles();
      _grid = TileGrid(
        scale: targetScale,
        tilePixels: _rasterizer.tilePixels,
      );
    }
    _resetStats();
    _ensureVisible();
    _finish();
  }

  /// Applies [scene]: composites appended elements, re-rasterizes dirty tiles.
  void update(ElementScene scene) {
    final diff = diffScenes(_scene, scene);
    final prev = _scene;
    _scene = scene;
    if (diff.isEmpty && prev != null) return;
    final grid = _grid;
    if (grid == null) return;

    _resetStats();

    if (diff.full) {
      _store.clear();
    } else if (diff.appendedOnTop.isNotEmpty) {
      _composite(scene, grid, diff.appendedOnTop);
    } else {
      _store.dropIn(grid, diff.dirty);
    }
    // Legacy images show the old scene: never keep them past a change.
    _releaseLegacy();
    _ensureVisible();
    _finish();
  }

  /// Re-rasterizes tiles in [rects] for an unchanged scene (image loaded).
  void invalidate(Iterable<ui.Rect> rects) {
    final grid = _grid;
    if (grid == null || _scene == null) return;
    _resetStats();
    _store.dropIn(grid, rects);
    _releaseLegacy();
    _ensureVisible();
    _finish();
  }

  /// Rasterizes the pending tile nearest to the viewport centre.
  /// Returns false when nothing is pending.
  bool rasterizeNextPending() {
    final grid = _grid;
    final scene = _scene;
    if (_pending.isEmpty || grid == null || scene == null) return false;
    final best = grid.nearest(_pending, _viewport.center);
    _pending.remove(best);
    _resetStats();
    _rasterizeTile(grid, scene, best);
    if (_pending.isEmpty) _releaseLegacy();
    _finish();
    return true;
  }

  void _resetStats() {
    _lastRecorded = 0;
    _lastKeys = [];
  }

  void _composite(ElementScene scene, TileGrid grid, List<String> ids) {
    final appended = [for (final id in ids) scene.byId[id]!];
    final sub = buildSceneRenderer(
      subScene(scene, appended, ids),
      _strokeRenderer,
      _cacheManager,
    );

    final keys = <TileKey>{
      for (final e in appended) ...grid.keysIn(e.bounds),
    };
    for (final key in keys) {
      if (_store.vector.contains(key)) continue;
      final tile = _store.tiles[key];
      if (tile == null && !_store.has(key)) continue; // built later
      final rect = grid.rectOf(key);
      final hits = appended.where((e) => e.bounds.overlaps(rect)).toList();
      if (hits.isEmpty) continue;
      if (hits.any((e) => e.isVectorOnly)) {
        _store.drop(key);
        _store.vector.add(key);
        continue;
      }
      final built = _builder.build(
        key: key,
        rect: rect,
        scale: grid.scale,
        renderer: sub,
        base: tile,
        blend: hits.any((e) => e.usesBlend),
      );
      _put(built, hits.length);
    }
  }

  /// Rasterizes missing visible tiles, or queues them while legacy tiles
  /// can stand in.
  void _ensureVisible() {
    final grid = _grid;
    final scene = _scene;
    _pending.clear();
    if (grid == null || scene == null) return;
    final defer = _legacy.isNotEmpty;
    for (final key in grid.keysIn(_viewport)) {
      if (_store.has(key)) continue;
      final rect = grid.rectOf(key);
      if (!scene.entries.any((e) => e.bounds.overlaps(rect))) {
        _store.empty.add(key);
      } else if (scene.hasVectorOnlyIn(rect)) {
        _store.vector.add(key);
      } else if (defer) {
        _pending.add(key);
      } else {
        _rasterizeTile(grid, scene, key);
      }
    }
  }

  void _rasterizeTile(TileGrid grid, ElementScene scene, TileKey key) {
    final rect = grid.rectOf(key);
    final hits = scene.entries.where((e) => e.bounds.overlaps(rect)).toList();
    if (hits.isEmpty) {
      _store.empty.add(key);
      return;
    }
    final built = _builder.build(
      key: key,
      rect: rect,
      scale: grid.scale,
      renderer: buildSceneRenderer(scene, _strokeRenderer, _cacheManager),
      blend: hits.any((e) => e.usesBlend),
    );
    _put(built, hits.length);
  }

  void _put(CachedTile tile, int recorded) {
    _store.replace(tile);
    _rasterCount++;
    _lastKeys = [..._lastKeys, tile.key];
    _lastRecorded = recorded > _lastRecorded ? recorded : _lastRecorded;
  }

  /// Moves the viewport tiles to [legacyTiles] ahead of a scale change.
  void _retireTiles() {
    if (_store.tiles.isEmpty) {
      _store.empty.clear();
      return;
    }
    _releaseLegacy();
    _legacy = _store.takeOverlapping(_viewport);
  }

  void _releaseLegacy() {
    _legacy.forEach((t) => t.dispose());
    _legacy = const [];
  }

  void _finish() {
    final grid = _grid;
    final visibleKeys = grid == null ? <TileKey>[] : grid.keysIn(_viewport);
    _clock++;
    _visible = [
      for (final k in visibleKeys)
        if (_store.tiles[k] != null) _store.tiles[k]!..lastUsed = _clock,
    ];
    _pendingRects = [
      if (grid != null)
        for (final k in _pending) grid.rectOf(k),
    ];
    _vectorRects = [
      if (grid != null)
        for (final k in visibleKeys)
          if (_store.vector.contains(k)) grid.rectOf(k),
    ];
    _store.evict(visibleKeys.toSet(), budgetBytes);
    notifyListeners();
  }

  @override
  void dispose() {
    _store.clear();
    _releaseLegacy();
    _visible = const [];
    super.dispose();
  }
}
