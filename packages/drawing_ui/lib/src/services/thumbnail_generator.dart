import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:drawing_ui/src/services/page_rasterizer.dart';

/// Generates thumbnail images for pages.
///
/// A thumbnail is a scaled-down [PageRasterizer] render: the same painters as
/// the canvas for the background and the layer content. There is no second,
/// simplified renderer here.
class ThumbnailGenerator {
  /// Default thumbnail width in pixels.
  static const double defaultWidth = 150;

  /// Default thumbnail height in pixels.
  static const double defaultHeight = 200;

  /// Generates a cache key for a page.
  ///
  /// The key includes the page ID and last update timestamp,
  /// ensuring the cache is invalidated when content changes.
  static String getCacheKey(Page page) {
    return '${page.id}_${page.updatedAt.millisecondsSinceEpoch}';
  }

  /// Generates a thumbnail image for the given page.
  ///
  /// Returns a PNG image as [Uint8List], or null if generation fails.
  ///
  /// The thumbnail is scaled proportionally to fit within [width] x [height],
  /// maintaining the aspect ratio of the page.
  static Future<Uint8List?> generate(
    Page page, {
    double width = defaultWidth,
    double height = defaultHeight,
    Color backgroundColor = Colors.white,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  }) async {
    try {
      return await PageRasterizer.renderPng(
        page,
        width: width.toInt(),
        height: height.toInt(),
        backgroundColor: backgroundColor,
        pdfPaths: pdfPaths,
      );
    } catch (_) {
      // Return null on any error (e.g., invalid dimensions, rendering issues)
      return null;
    }
  }
}
