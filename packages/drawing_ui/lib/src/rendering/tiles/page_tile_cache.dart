import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/foundation.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/rendering/element_scene_renderer.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/element_scene.dart';
import 'package:drawing_ui/src/rendering/tiles/scene_diff.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_rasterizer.dart';

/// A rasterized tile: [image] covers [rect] in page space.
class CachedTile {
  CachedTile(this.key, this.rect, this.image)
      : bytes = image.width * image.height * 4;

  final TileKey key;
  final ui.Rect rect;
  final ui.Image image;
  final int bytes;
  int _lastUsed = 0;
}

/// Raster cache of the committed content of one (page, layer).
///
/// Owns every [ui.Image] it holds and disposes them on eviction, replacement
/// and [dispose]. Only visible tiles are kept fresh; dirty off-screen tiles
/// are dropped and rebuilt when they scroll into view.
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

  final Map<TileKey, CachedTile> _tiles = {};

  /// Visible tiles that were rasterized but hold no content.
  final Set<TileKey> _empty = {};
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

  /// Bytes held by cached tile images.
  int get cachedBytes => _tiles.values.fold(0, (sum, t) => sum + t.bytes);

  /// Sets the visible page rect and the raster scale (zoom * pixel ratio).
  /// Tiles are rebuilt at a new scale; while [interacting] nothing is
  /// rasterized.
  void setViewport(
    ui.Rect visiblePageRect,
    double targetScale, {
    required bool interacting,
  }) {
    _viewport = visiblePageRect;
    if (interacting) return;
    if (_grid?.scale != targetScale) {
      _clearTiles();
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
      _clearTiles();
    } else if (diff.appendedOnTop.isNotEmpty) {
      _composite(scene, grid, diff.appendedOnTop);
    } else {
      for (final rect in diff.dirty) {
        for (final key in grid.keysIn(rect)) {
          _drop(key);
        }
      }
    }
    _ensureVisible();
    _finish();
  }

  void _composite(ElementScene scene, TileGrid grid, List<String> ids) {
    final appended = [for (final id in ids) scene.byId[id]!];
    final sub = _renderer(
      ElementScene(
        strokes: [
          for (final e in appended)
            if (e.element is Stroke) e.element as Stroke,
        ],
        shapes: [
          for (final e in appended)
            if (e.element is Shape) e.element as Shape,
        ],
        images: [
          for (final e in appended)
            if (e.element is ImageElement) e.element as ImageElement,
        ],
        texts: [
          for (final e in appended)
            if (e.element is TextElement) e.element as TextElement,
        ],
        elementOrder: ids,
        pixelEraserPreview: scene.pixelEraserPreview,
      ),
    );

    final keys = <TileKey>{
      for (final e in appended) ...grid.keysIn(e.bounds),
    };
    for (final key in keys) {
      final tile = _tiles[key];
      if (tile == null && !_empty.contains(key)) continue; // built later
      final rect = grid.rectOf(key);
      final count = appended.where((e) => e.bounds.overlaps(rect)).length;
      if (count == 0) continue;
      final image = _rasterizer.rasterize(
        pageRect: rect,
        scale: grid.scale,
        base: tile?.image,
        paint: (canvas) => sub.paintRegion(canvas, rect),
      );
      _drop(key);
      _put(key, rect, image, count);
    }
  }

  void _ensureVisible() {
    final grid = _grid;
    final scene = _scene;
    if (grid == null || scene == null) return;
    final keys = grid.keysIn(_viewport);
    final full = _renderer(scene);
    for (final key in keys) {
      if (_tiles.containsKey(key) || _empty.contains(key)) continue;
      final rect = grid.rectOf(key);
      final count = scene.entries.where((e) => e.bounds.overlaps(rect)).length;
      if (count == 0) {
        _empty.add(key);
        continue;
      }
      final image = _rasterizer.rasterize(
        pageRect: rect,
        scale: grid.scale,
        paint: (canvas) => full.paintRegion(canvas, rect),
      );
      _put(key, rect, image, count);
    }
  }

  ElementSceneRenderer _renderer(ElementScene s) => ElementSceneRenderer(
        strokes: s.strokes,
        shapes: s.shapes,
        images: s.images,
        texts: s.texts,
        elementOrder: s.elementOrder,
        renderer: _strokeRenderer,
        cacheManager: _cacheManager,
        excludedStrokeIds: s.excludedIds,
        excludedShapeIds: s.excludedIds,
        excludedImageIds: s.excludedIds,
        excludedTextIds: s.excludedIds,
        pixelEraserPreview: s.pixelEraserPreview,
        strokeEraserPreview: s.strokeEraserPreview,
      );

  void _put(TileKey key, ui.Rect rect, ui.Image image, int recorded) {
    _tiles[key] = CachedTile(key, rect, image);
    _rasterCount++;
    _lastKeys = [..._lastKeys, key];
    if (recorded > _lastRecorded) _lastRecorded = recorded;
  }

  void _drop(TileKey key) {
    _tiles.remove(key)?.image.dispose();
    _empty.remove(key);
  }

  void _clearTiles() {
    for (final t in _tiles.values) {
      t.image.dispose();
    }
    _tiles.clear();
    _empty.clear();
  }

  void _finish() {
    final grid = _grid;
    final visibleKeys = grid == null ? <TileKey>{} : grid.keysIn(_viewport);
    final visibleSet = visibleKeys.toSet();
    _clock++;
    _visible = [
      for (final k in visibleKeys)
        if (_tiles[k] != null) _tiles[k]!.._lastUsed = _clock,
    ];
    _evict(visibleSet);
    notifyListeners();
  }

  /// Drops least recently used off-screen tiles until within [budgetBytes].
  void _evict(Set<TileKey> visibleSet) {
    var total = cachedBytes;
    if (total <= budgetBytes) return;
    final candidates = [
      for (final t in _tiles.values)
        if (!visibleSet.contains(t.key)) t,
    ]..sort((a, b) => a._lastUsed.compareTo(b._lastUsed));
    for (final t in candidates) {
      if (total <= budgetBytes) break;
      total -= t.bytes;
      _drop(t.key);
    }
  }

  @override
  void dispose() {
    _clearTiles();
    _visible = const [];
    super.dispose();
  }
}
