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

  /// If set, this image's live position/size is used instead of the
  /// committed version in [images]. This enables real-time drag feedback.
  final ImageElement? overrideImage;

  ImageElementPainter({
    required this.images,
    required this.cacheManager,
    this.overrideImage,
  }) : super(repaint: cacheManager);

  @override
  void paint(Canvas canvas, Size size) {
    for (final image in images) {
      // Use live override position when dragging/resizing
      final effective =
          (overrideImage != null && overrideImage!.id == image.id)
              ? overrideImage!
              : image;
      _drawImage(canvas, effective);
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
    final iconSize = (element.width < element.height
            ? element.width
            : element.height) *
        0.3;
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
        oldDelegate.overrideImage != overrideImage ||
        (overrideImage != null &&
            oldDelegate.overrideImage != null &&
            (overrideImage!.x != oldDelegate.overrideImage!.x ||
                overrideImage!.y != oldDelegate.overrideImage!.y ||
                overrideImage!.width != oldDelegate.overrideImage!.width ||
                overrideImage!.height != oldDelegate.overrideImage!.height));
  }
}

/// Loads and caches [ui.Image] objects from file paths.
///
/// Extends [ChangeNotifier] so painters using this as a repaint listenable
/// automatically repaint when a new image finishes loading.
class ImageCacheManager extends ChangeNotifier {
  final Map<String, ui.Image> _cache = {};
  final Set<String> _loading = {};

  /// Get a cached image, or null if not yet loaded.
  ui.Image? get(String filePath) => _cache[filePath];

  /// Load an image from file path if not already cached or loading.
  /// Notifies listeners when loading completes (triggers repaint).
  Future<void> loadImage(String filePath) async {
    if (_cache.containsKey(filePath) || _loading.contains(filePath)) return;
    _loading.add(filePath);

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _loading.remove(filePath);
        return;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _cache[filePath] = frame.image;
      notifyListeners();
    } catch (_) {
      // Silently fail - placeholder will continue to show
    } finally {
      _loading.remove(filePath);
    }
  }

  @override
  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    super.dispose();
  }
}
