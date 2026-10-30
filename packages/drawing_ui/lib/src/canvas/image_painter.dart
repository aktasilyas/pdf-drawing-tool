import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// CustomPainter for rendering [ImageElement]s on the drawing canvas.
///
/// Uses [ImageCacheManager] as a repaint listenable so that when images
/// finish loading the painter automatically repaints.
class ImageElementPainter extends CustomPainter {
  final List<ImageElement> images;
  final ImageCacheManager cacheManager;

  /// Image IDs to exclude from rendering (used during live selection transform).
  final Set<String> excludedImageIds;

  ImageElementPainter({
    required this.images,
    required this.cacheManager,
    this.excludedImageIds = const {},
  }) : super(repaint: cacheManager);

  @override
  void paint(Canvas canvas, Size size) {
    for (final image in images) {
      if (excludedImageIds.contains(image.id)) continue;
      _drawImage(canvas, image);
    }
  }

  void _drawImage(Canvas canvas, ImageElement element) {
    final cachedImage = cacheManager.get(element.filePath);

    if (cachedImage == null) {
      _drawPlaceholder(canvas, element);
      cacheManager.loadImage(element.filePath);
      return;
    }

    canvas.save();

    if (element.rotation != 0.0) {
      final cx = element.x + element.width / 2;
      final cy = element.y + element.height / 2;
      canvas.translate(cx, cy);
      canvas.rotate(element.rotation);
      canvas.translate(-cx, -cy);
    }

    final src = Rect.fromLTWH(
      0,
      0,
      cachedImage.width.toDouble(),
      cachedImage.height.toDouble(),
    );
    final dst = Rect.fromLTWH(
      element.x,
      element.y,
      element.width,
      element.height,
    );

    canvas.drawImageRect(cachedImage, src, dst, Paint());

    canvas.restore();
  }

  void _drawPlaceholder(Canvas canvas, ImageElement element) {
    final rect = Rect.fromLTWH(
      element.x,
      element.y,
      element.width,
      element.height,
    );

    final bgPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);

    // Small icon indicator in center
    final iconSize =
        (element.width < element.height ? element.width : element.height) * 0.3;
    final iconRect = Rect.fromCenter(
      center: rect.center,
      width: iconSize,
      height: iconSize,
    );
    final iconPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(iconRect, iconPaint);
  }

  @override
  bool shouldRepaint(covariant ImageElementPainter oldDelegate) {
    return oldDelegate.images != images ||
        oldDelegate.excludedImageIds != excludedImageIds;
  }
}

/// Loads and caches [ui.Image] objects from file paths.
///
/// Extends [ChangeNotifier] so painters using this as a repaint listenable
/// automatically repaint when a new image finishes loading.
///
/// Cache keys are the *stored* paths (as persisted in [ImageElement.filePath]);
/// [paths] turns them into absolute files when loading, so images survive a
/// change of the documents directory.
class ImageCacheManager extends ChangeNotifier {
  /// Creates a cache that opens files through [paths].
  ImageCacheManager({
    this.paths = PdfPathResolver.passthrough,
    this.byteBudget = defaultByteBudget,
    this.protectWindow = const Duration(seconds: 2),
  });

  /// Resolves stored image paths to absolute file paths.
  final PdfPathResolver paths;

  /// Longest edge, in pixels, an image is decoded at.
  static const int maxDecodeEdge = 2048;

  /// Default decoded-bytes budget of the cache (RGBA, 4 bytes per pixel).
  static const int defaultByteBudget = 96 * 1024 * 1024;

  /// Budget for one-shot offline renderers, which must keep every image
  /// alive until their synchronous paint.
  static const int unboundedBudget = 1 << 40;

  /// Images read through [get] within this window are never evicted, so a
  /// visible set larger than the budget cannot evict-and-reload in a loop
  /// (the cache then temporarily exceeds the budget).
  final Duration protectWindow;

  /// Decoded-bytes budget; least recently used images are evicted beyond it.
  final int byteBudget;

  // Insertion order doubles as LRU order: the first key is the oldest.
  final Map<String, ui.Image> _cache = {};
  final Set<String> _loading = {};
  final Map<String, int> _touchedMs = {};
  final Stopwatch _clock = Stopwatch()..start();
  int _bytes = 0;

  /// Decoded bytes currently held.
  int get cachedBytes => _bytes;

  /// Get a cached image, or null if not yet loaded (or evicted).
  ui.Image? get(String filePath) {
    final image = _cache.remove(filePath);
    if (image == null) return null;
    _cache[filePath] = image; // mark as most recently used
    _touchedMs[filePath] = _clock.elapsedMilliseconds;
    return image;
  }

  /// Load an image from file path if not already cached or loading.
  /// Notifies listeners when loading completes (triggers repaint).
  Future<void> loadImage(String filePath) async {
    if (_cache.containsKey(filePath) || _loading.contains(filePath)) return;
    _loading.add(filePath);

    try {
      final file = File(paths.resolve(filePath));
      if (!file.existsSync()) {
        _loading.remove(filePath);
        return;
      }

      final bytes = await file.readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (w, h) {
          final long = w >= h ? w : h;
          if (long <= maxDecodeEdge)
            return ui.TargetImageSize(width: w, height: h);
          final scale = maxDecodeEdge / long;
          return ui.TargetImageSize(
            width: (w * scale).round(),
            height: (h * scale).round(),
          );
        },
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      _insert(filePath, frame.image);
      notifyListeners();
    } catch (_) {
      // Silently fail - placeholder will continue to show
    } finally {
      _loading.remove(filePath);
    }
  }

  void _insert(String filePath, ui.Image image) {
    _cache.remove(filePath)?.dispose();
    _cache[filePath] = image;
    _recount();
    // Evict oldest first, skipping the new image and recently painted ones.
    final now = _clock.elapsedMilliseconds;
    for (final key in _cache.keys.toList()) {
      if (_bytes <= byteBudget) break;
      if (key == filePath) continue;
      final touched = _touchedMs[key];
      if (touched != null && now - touched < protectWindow.inMilliseconds) {
        continue;
      }
      _cache.remove(key)!.dispose();
      _touchedMs.remove(key);
      _recount();
    }
  }

  void _recount() {
    var total = 0;
    for (final i in _cache.values) {
      total += i.width * i.height * 4;
    }
    _bytes = total;
  }

  /// Evicts every image not read through [get] within [protectWindow]
  /// (memory pressure). Evicted images reload on their next paint.
  void trim() {
    final now = _clock.elapsedMilliseconds;
    for (final key in _cache.keys.toList()) {
      final touched = _touchedMs[key];
      if (touched != null && now - touched < protectWindow.inMilliseconds) {
        continue;
      }
      _cache.remove(key)!.dispose();
      _touchedMs.remove(key);
    }
    _recount();
  }

  /// Stores [image] for [filePath] as if it had just loaded, and notifies.
  @visibleForTesting
  void debugPut(String filePath, ui.Image image) {
    _insert(filePath, image);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _bytes = 0;
    super.dispose();
  }
}
