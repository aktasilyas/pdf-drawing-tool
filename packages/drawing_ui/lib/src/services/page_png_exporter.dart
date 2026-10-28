import 'dart:math' as math;
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;

import 'package:drawing_ui/src/services/page_rasterizer.dart';
import 'package:drawing_ui/src/services/pdf_export_bounds.dart';

/// Pixel layout of a PNG export: which part of the page, at what size.
typedef PagePngLayout = ({Rect region, int width, int height, double scale});

/// Exports one page as a PNG image of the page itself, rendered off-screen
/// with [PageRasterizer] — independent of the on-screen zoom, pan and
/// selection overlays.
abstract final class PagePngExporter {
  /// Pixels per page point.
  static const double scale = 2;

  /// Longest side of the exported image, in pixels.
  static const int maxSide = 4096;

  /// The exported area of [page] and the image size.
  ///
  /// A paged document exports the page rect. An infinite canvas exports the
  /// page rect grown to hold all visible content (the same bounds as its PDF
  /// export). The image is [scale] x the area, shrunk so the longest side
  /// is at most [maxSide].
  static PagePngLayout layout(Page page, {required bool infiniteCanvas}) {
    final Rect region;
    if (infiniteCanvas) {
      final b = infiniteCanvasExportBounds(page);
      region = Rect.fromLTWH(-b.offsetX, -b.offsetY, b.width, b.height);
    } else {
      region = Rect.fromLTWH(0, 0, page.size.width, page.size.height);
    }
    final longest = math.max(region.width, region.height);
    final s = math.min(scale, maxSide / longest);
    return (
      region: region,
      width: math.max(1, (region.width * s).round()),
      height: math.max(1, (region.height * s).round()),
      scale: s,
    );
  }

  /// Renders [page] to PNG bytes, flagging a PDF background that could not be
  /// loaded. Throws if rendering fails.
  static Future<PageRasterPng> export(
    Page page, {
    required bool infiniteCanvas,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  }) {
    final l = layout(page, infiniteCanvas: infiniteCanvas);
    return PageRasterizer.renderPngWithStatus(
      page,
      width: l.width,
      height: l.height,
      region: l.region,
      pdfPaths: pdfPaths,
      pdfRenderScale: l.scale,
    );
  }
}
