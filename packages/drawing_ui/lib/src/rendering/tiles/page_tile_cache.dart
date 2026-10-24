import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/element_scene.dart';
import 'package:drawing_ui/src/rendering/tiles/scene_diff.dart';
import 'package:drawing_ui/src/rendering/tiles/scene_renderer_factory.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_rasterizer.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_store.dart';

/// Raster cache of the committed content of one (page, layer).
///
/// Owns every [ui.Image] it holds and disposes them on eviction, replacement
/// and [dispose]. Only visible tiles are kept fresh; dirty off-screen tiles
/// are dropped and rebuilt when they scroll into view.
///
/// When the raster scale changes while tiles exist, the old tiles are kept as
/// [legacyTiles] and the visible tiles at the new scale become pending. A
/// `TileRasterScheduler` fills them progressively via [rasterizeNextPending];
/// the painter draws the legacy images (or vectors) in the meantime.
class PageTileCache extends ChangeNotifier {
  PageTileCache({
    required FlutterStrokeRenderer strokeRenderer,
    required ImageCacheManager cacheManager,
    this.budgetBytes = 64 << 20,
    TileRasterizer rasterizer = const TileRasterizer(),
  })  : _strokeRenderer = strokeRenderer,
        _cacheManager = cacheManager,
        _rasterizer = rasterizer;

  final FlutterStrokeRenderer _strokeRenderer;
  final ImageCacheManager _cacheManager;
  final TileRasterizer _rasterizer;
  final int budgetBytes;

  final TileStore _store = TileStore();

  /// Visible tiles with content that wait for the scheduler.
  final List<TileKey> _pending = [];
  List<ui.Rect> _pendingRects = const [];

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

  /// Page rects of visible tiles that are not rasterized yet.
  List<ui.Rect> get pendingRects => _pendingRects;

  /// Whether visible tiles at the current scale still wait to be rasterized.
  bool get hasPending => _pending.isNotEmpty;

  int get pendingCount => _pending.length;

  /// Total tile rasterizations since creation.
  @visibleForTesting
  int get debugRasterCount => _rasterCount;

  /// Most elements recorded into a single tile during the last call that
  /// changed pixels. Compositing a new stroke counts only the new elements.
  @visibleForTesting
  int get debugLastRecordedElements => _lastRecorded;

  /// Tiles rasterized by the last call that changed pixels.
  @visibleForTesting
  List<TileKey> get debugRasterizedKeys => _lastKeys;

  @visibleForTesting
  List<TileKey> get debugPendingKeys => List.of(_pending);

  @visibleForTesting
  void debugDropLegacy() => _releaseLegacy();

  /// Bytes held by cached tile images.
  int get cachedBytes => _store.bytes;

  /// Paints [rect] of the current scene as vectors (cold-tile fallback).
  void paintVectorRegion(ui.Canvas canvas, ui.Rect rect) {
    final scene = _scene;
    if (scene == null) return;
    buildSceneRenderer(scene, _strokeRenderer, _cacheManager)
        .paintRegion(canvas, rect);
  }

  /// Sets the visible page rect and the raster scale (zoom * pixel ratio).
  ///
  /// While [interacting] nothing is rasterized and existing tiles keep being
  /// drawn scaled. On settle at a new scale (beyond a small epsilon) the old
  /// tiles become [legacyTiles] and the new visible tiles become pending; if
  /// there is nothing to fall back to they are rasterized right away.
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
    _lastRecorded = 0;
    _lastKeys = [];
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

    _lastRecorded = 0;
    _lastKeys = [];

    if (diff.full) {
      _store.clear();
    } else if (diff.appendedOnTop.isNotEmpty) {
      _composite(scene, grid, diff.appendedOnTop);
    } else {
      for (final rect in diff.dirty) {
        for (final key in grid.keysIn(rect)) {
          _store.drop(key);
        }
      }
    }
    // Legacy images show the old scene: never keep them past a change.
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
    final centre = _viewport.center;
    var best = _pending.first;
    var bestDist = double.infinity;
    for (final k in _pending) {
      final d = (grid.rectOf(k).center - centre).distanceSquared;
      if (d < bestDist) {
        best = k;
        bestDist = d;
      }
    }
    _pending.remove(best);
    _lastRecorded = 0;
    _lastKeys = [];
    _rasterizeTile(grid, scene, best);
    if (_pending.isEmpty) _releaseLegacy();
    _finish();
    return true;
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
      final tile = _store.tiles[key];
      if (tile == null && !_store.has(key)) continue; // built later
      final rect = grid.rectOf(key);
      final count = appended.where((e) => e.bounds.overlaps(rect)).length;
      if (count == 0) continue;
      final image = _rasterizer.rasterize(
        pageRect: rect,
        scale: grid.scale,
        base: tile?.image,
        paint: (canvas) => sub.paintRegion(canvas, rect),
      );
      _store.drop(key);
      _put(key, rect, image, count);
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
      } else if (defer) {
        _pending.add(key);
      } else {
        _rasterizeTile(grid, scene, key);
      }
    }
  }

  void _rasterizeTile(TileGrid grid, ElementScene scene, TileKey key) {
    final rect = grid.rectOf(key);
    final count = scene.entries.where((e) => e.bounds.overlaps(rect)).length;
    if (count == 0) {
      _store.empty.add(key);
      return;
    }
    final full = buildSceneRenderer(scene, _strokeRenderer, _cacheManager);
    final image = _rasterizer.rasterize(
      pageRect: rect,
      scale: grid.scale,
      paint: (canvas) => full.paintRegion(canvas, rect),
    );
    _put(key, rect, image, count);
  }

  void _put(TileKey key, ui.Rect rect, ui.Image image, int recorded) {
    _store.tiles[key] = CachedTile(key, rect, image);
    _rasterCount++;
    _lastKeys = [..._lastKeys, key];
    if (recorded > _lastRecorded) _lastRecorded = recorded;
  }

  /// Moves the current tiles to [legacyTiles] ahead of a scale change. Only
  /// tiles in the viewport are kept. If no tile exists at the current scale
  /// yet, the older legacy tiles stay in place.
  void _retireTiles() {
    if (_store.tiles.isEmpty) {
      _store.empty.clear();
      return;
    }
    _releaseLegacy();
    _legacy = _store.takeOverlapping(_viewport);
  }

  void _releaseLegacy() {
    for (final t in _legacy) {
      t.image.dispose();
    }
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
