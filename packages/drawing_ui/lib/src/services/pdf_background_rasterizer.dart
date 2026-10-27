import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:pdf/pdf.dart';

import 'package:drawing_ui/src/canvas/page_background_raster.dart';

import 'pdf_compressed_image.dart';
import 'pdf_raster_layer_renderer.dart';

/// Exports template and cover backgrounds with the canvas painters.
///
/// The background is rasterized through [PageBackgroundRaster] (the same
/// painters as the canvas, picker previews and thumbnails) at the export DPI
/// and embedded as one opaque full-page image. Identical backgrounds of the
/// same size share one embedded image within an export ([imageFor] caches by
/// `(background, width, height, dpi)`). Use one instance per export.
///
/// Legacy `blank` / `grid` / `lined` / `dotted` backgrounds stay on the
/// vector path in `PdfContentPainter`; PDF backgrounds are embedded
/// separately.
class PdfBackgroundRasterizer {
  /// Highest DPI used for a background raster. Paper lines and covers gain
  /// nothing visible above this, while a 600 dpi A4 raster would need about
  /// 140 MB of transient RGBA memory.
  static const int maxDpi = 300;

  /// Longest side of a background raster in pixels (bounds memory for large
  /// infinite-canvas pages).
  static const int maxSidePx = 4096;

  final _cache = <(PageBackground, double, double, int), PdfImage>{};

  /// Whether [background] is exported through this rasterizer.
  static bool handles(PageBackground background) =>
      background.type == BackgroundType.template ||
      background.type == BackgroundType.cover;

  /// Number of distinct background images embedded since the last [clear].
  int get cachedImageCount => _cache.length;

  /// Drops the per-export cache.
  void clear() => _cache.clear();

  /// The embedded image for [background] on a `w`×`h` page, rendered once
  /// per distinct `(background, w, h, dpi)` and reused afterwards. Null when
  /// rendering fails (the caller falls back to the base color).
  Future<PdfImage?> imageFor(
    PdfDocument doc,
    PageBackground background,
    double w,
    double h,
    int dpi,
  ) async {
    final key = (background, w, h, dpi);
    final cached = _cache[key];
    if (cached != null) return cached;
    final raw = await render(background, w, h, dpi);
    if (raw == null) return null;
    return _cache[key] = addCompressedRgbImage(doc, raw);
  }

  /// Renders [background] for a `w`×`h` page (PDF points) to opaque RGBA
  /// pixels at [dpi] (capped by [maxDpi] and [maxSidePx]).
  Future<PdfRawImage?> render(
    PageBackground background,
    double w,
    double h,
    int dpi,
  ) async {
    if (w <= 0 || h <= 0) return null;
    final scale = scaleFor(w, h, dpi);
    final pxW = math.max(1, (w * scale).round());
    final pxH = math.max(1, (h * scale).round());

    final coverImage = await PageBackgroundRaster.prepare(background);
    ui.Image? image;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(w, h);
      canvas.scale(pxW / w, pxH / h);
      // White paper under a translucent base color keeps the raster opaque.
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      PageBackgroundRaster.paint(canvas, background, size, coverImage);
      final picture = recorder.endRecording();
      image = await picture.toImage(pxW, pxH);
      picture.dispose();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return null;
      return (bytes: data.buffer.asUint8List(), width: pxW, height: pxH);
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      coverImage?.dispose();
    }
  }

  /// Pixels per PDF point for a `w`×`h` page at [dpi].
  static double scaleFor(double w, double h, int dpi) {
    final scale = math.min(dpi, maxDpi) / 72.0;
    final longest = math.max(w, h);
    return math.min(scale, maxSidePx / longest);
  }
}
