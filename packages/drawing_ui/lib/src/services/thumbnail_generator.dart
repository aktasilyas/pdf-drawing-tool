import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:drawing_ui/src/services/page_rasterizer.dart';
import 'package:drawing_ui/src/services/pdf_document_pool.dart';

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
  ///
  /// A PDF background is decoded at the thumbnail's size. Pass the editor's
  /// [pdfDocuments] so thumbnails of one PDF share its open document;
  /// without it the document is opened and closed for this thumbnail.
  static Future<Uint8List?> generate(
    Page page, {
    double width = defaultWidth,
    double height = defaultHeight,
    Color backgroundColor = Colors.white,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
    PdfDocumentPool? pdfDocuments,
  }) async {
    final ownPool =
        pdfDocuments == null && page.background.type == BackgroundType.pdf
            ? PdfDocumentPool(maxOpen: 1)
            : null;
    try {
      return await PageRasterizer.renderPng(
        page,
        width: width.toInt(),
        height: height.toInt(),
        backgroundColor: backgroundColor,
        pdfPaths: pdfPaths,
        pdfDocuments: pdfDocuments ?? ownPool,
      );
    } catch (_) {
      // Return null on any error (e.g., invalid dimensions, rendering issues)
      return null;
    } finally {
      await ownPool?.close();
    }
  }
}
