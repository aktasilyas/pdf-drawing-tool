import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/canvas/editor_memory_pressure_observer.dart';
import 'package:drawing_ui/src/canvas/element_preview_painter.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/tiled_element_painter.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

/// Committed content of the active layer, drawn from a per-page tile cache.
///
/// The [State] owns the [PageTileCache] and its raster scheduler. Give the
/// widget a `ValueKey` of (page, layer): a new key disposes the cache. While
/// [isZooming] the cached tiles are only scaled; about 120 ms after it turns
/// false the visible tiles are re-rasterized at `zoom * devicePixelRatio`.
class ActiveLayerContent extends StatefulWidget {
  const ActiveLayerContent({
    super.key,
    required this.scene,
    required this.transform,
    required this.viewportSize,
    required this.isZooming,
    required this.renderer,
    required this.cacheManager,
    this.activeShape,
    this.activeText,
    this.selectionColor = const Color(0xFF10B981),
    this.zoomSettleDelay = const Duration(milliseconds: 120),
  });

  final ElementScene scene;
  final CanvasTransform transform;

  /// Size of the viewport the transform maps the page into.
  final Size viewportSize;
  final bool isZooming;
  final FlutterStrokeRenderer renderer;
  final ImageCacheManager cacheManager;
  final Shape? activeShape;
  final TextElement? activeText;
  final Color selectionColor;
  final Duration zoomSettleDelay;

  @override
  State<ActiveLayerContent> createState() => ActiveLayerContentState();
}

class ActiveLayerContentState extends State<ActiveLayerContent> {
  static const double _maxScale = 8;
  late PageTileCache _cache;
  late TileRasterScheduler _scheduler;
  Timer? _settleTimer;
  bool _interacting = false;
  bool _hasRaster = false;
  ElementScene? _applied;
  late final EditorMemoryPressureObserver _memoryPressure;

  /// File paths of applied scene images that have not loaded yet.
  Set<String> _unloaded = const {};

  @visibleForTesting
  PageTileCache get cache => _cache;

  @override
  void initState() {
    super.initState();
    _createCache();
    widget.cacheManager.addListener(_onImagesChanged);
    _memoryPressure =
        EditorMemoryPressureObserver(() => _cache.trimToVisible());
  }

  void _createCache() {
    _cache = PageTileCache(
      strokeRenderer: widget.renderer,
      cacheManager: widget.cacheManager,
    );
    _scheduler = TileRasterScheduler(cache: _cache);
    _hasRaster = false;
    _applied = null;
  }

  void _disposeCache() {
    _scheduler.dispose();
    _cache.dispose();
  }

  /// Late-loading images change the pixels of the tiles cached with their
  /// placeholder: re-raster only the tiles under the images that loaded.
  void _onImagesChanged() {
    if (!mounted || _unloaded.isEmpty) return;
    final manager = widget.cacheManager;
    final loaded = {
      for (final path in _unloaded)
        if (manager.get(path) != null) path,
    };
    if (loaded.isEmpty) return;
    _unloaded = _unloaded.difference(loaded);
    _cache.invalidate([
      for (final image in _applied?.images ?? const <ImageElement>[])
        if (loaded.contains(image.filePath)) imageBounds(image),
    ]);
  }

  /// Records which images of the applied scene are still placeholders.
  void _trackUnloaded(ElementScene scene) {
    _unloaded = {
      for (final image in scene.images)
        if (widget.cacheManager.get(image.filePath) == null) image.filePath,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apply();
  }

  @override
  void didUpdateWidget(ActiveLayerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cacheManager, widget.cacheManager)) {
      oldWidget.cacheManager.removeListener(_onImagesChanged);
      widget.cacheManager.addListener(_onImagesChanged);
    }
    _apply();
  }

  void _apply() {
    if (widget.isZooming) {
      _settleTimer?.cancel();
      _settleTimer = null;
      _interacting = true;
    } else if (_interacting && _settleTimer == null) {
      _settleTimer = Timer(widget.zoomSettleDelay, () {
        _settleTimer = null;
        _interacting = false;
        if (mounted) _pushViewport();
      });
    }
    _pushViewport();
  }

  void _pushViewport() {
    final t = widget.transform;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final zoom = t.zoom <= 0 ? 1.0 : t.zoom;
    final margin = 32 / zoom;
    final visible = Rect.fromLTWH(
      -t.offset.dx / zoom,
      -t.offset.dy / zoom,
      widget.viewportSize.width / zoom,
      widget.viewportSize.height / zoom,
    ).inflate(margin);
    // The first raster always happens, otherwise nothing would be drawn.
    final interacting = _interacting && _hasRaster;
    if (!(_applied?.isSameAs(widget.scene) ?? false)) {
      _cache.update(widget.scene);
      _applied = widget.scene;
      _trackUnloaded(widget.scene);
    }
    _cache.setViewport(
      visible,
      math.min(zoom * dpr, _maxScale),
      interacting: interacting,
    );
    if (!interacting) _hasRaster = true;
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _memoryPressure.dispose();
    widget.cacheManager.removeListener(_onImagesChanged);
    _disposeCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = RepaintBoundary(
      child: CustomPaint(
        size: widget.viewportSize,
        painter: TiledElementPainter(cache: _cache),
        isComplex: true,
      ),
    );
    if (widget.activeShape == null && widget.activeText == null) return tiles;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tiles,
        RepaintBoundary(
          child: CustomPaint(
            size: widget.viewportSize,
            painter: ElementPreviewPainter(
              renderer: widget.renderer,
              cacheManager: widget.cacheManager,
              activeShape: widget.activeShape,
              activeText: widget.activeText,
              selectionColor: widget.selectionColor,
            ),
            willChange: true,
          ),
        ),
      ],
    );
  }
}
