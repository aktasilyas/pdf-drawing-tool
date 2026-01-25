import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

/// Quality levels for PDF rendering.
enum RenderQuality {
  /// Low quality (72 DPI base).
  low,

  /// Medium quality (144 DPI base).
  medium,

  /// High quality (288 DPI base).
  high,

  /// Very high quality (432+ DPI base).
  veryHigh,
}

/// Options for rendering a PDF page.
class PDFRenderOptions {
  /// Zoom level (1.0 = 100%).
  final double zoom;

  /// Device pixel ratio.
  final double devicePixelRatio;

  /// Background color (ARGB).
  final int backgroundColor;

  /// Render quality level.
  final RenderQuality quality;

  const PDFRenderOptions({
    this.zoom = 1.0,
    this.devicePixelRatio = 1.0,
    this.backgroundColor = 0xFFFFFFFF,
    this.quality = RenderQuality.medium,
  });

  /// Creates a copy with new values.
  PDFRenderOptions copyWith({
    double? zoom,
    double? devicePixelRatio,
    int? backgroundColor,
    RenderQuality? quality,
  }) {
    return PDFRenderOptions(
      zoom: zoom ?? this.zoom,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      quality: quality ?? this.quality,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFRenderOptions &&
          zoom == other.zoom &&
          devicePixelRatio == other.devicePixelRatio &&
          backgroundColor == other.backgroundColor &&
          quality == other.quality;

  @override
  int get hashCode => Object.hash(zoom, devicePixelRatio, backgroundColor, quality);
}

/// Service for rendering PDF pages with zoom support.
class PDFPageRenderer {
  /// Base DPI for PDF rendering (standard PDF DPI).
  static const double baseDPI = 72.0;

  /// Calculates the DPI for a given zoom level and device pixel ratio.
  ///
  /// Formula: DPI = baseDPI × zoom × devicePixelRatio
  double calculateDPI({
    required double zoom,
    required double devicePixelRatio,
  }) {
    return baseDPI * zoom * devicePixelRatio;
  }

  /// Calculates the render width in pixels for a page.
  ///
  /// Converts from PDF points to pixels based on DPI.
  double calculateRenderWidth({
    required double pageWidth,
    required double dpi,
  }) {
    return pageWidth * (dpi / baseDPI);
  }

  /// Calculates the render height in pixels for a page.
  ///
  /// Converts from PDF points to pixels based on DPI.
  double calculateRenderHeight({
    required double pageHeight,
    required double dpi,
  }) {
    return pageHeight * (dpi / baseDPI);
  }

  /// Calculates the render size for a page.
  Size calculateRenderSize({
    required double pageWidth,
    required double pageHeight,
    required double dpi,
  }) {
    return Size(
      calculateRenderWidth(pageWidth: pageWidth, dpi: dpi),
      calculateRenderHeight(pageHeight: pageHeight, dpi: dpi),
    );
  }

  /// Determines the quality level based on zoom.
  RenderQuality getQualityLevel(double zoom) {
    if (zoom < 0.75) return RenderQuality.low;
    if (zoom < 1.5) return RenderQuality.medium;
    if (zoom < 3.0) return RenderQuality.high;
    return RenderQuality.veryHigh;
  }

  /// Gets the recommended DPI for a quality level.
  double getRecommendedDPI(RenderQuality quality, double devicePixelRatio) {
    final baseDPI = switch (quality) {
      RenderQuality.low => 72.0,
      RenderQuality.medium => 144.0,
      RenderQuality.high => 288.0,
      RenderQuality.veryHigh => 432.0,
    };

    return baseDPI * devicePixelRatio;
  }

  /// Validates a page number for a document.
  bool isValidPageNumber(int pageNumber, int totalPages) {
    return pageNumber >= 1 && pageNumber <= totalPages;
  }

  /// Generates a cache key for a rendered page.
  String generateCacheKey({
    required String documentId,
    required int pageNumber,
    required PDFRenderOptions options,
  }) {
    return '${documentId}_p${pageNumber}_z${options.zoom}_dpr${options.devicePixelRatio}_q${options.quality.name}';
  }

  /// Renders a PDF page to bytes.
  ///
  /// Returns PNG image data for the rendered page.
  Future<Uint8List?> renderPage(
    PdfDocument document,
    int pageNumber, {
    required PDFRenderOptions options,
  }) async {
    try {
      // Validate page number
      if (!isValidPageNumber(pageNumber, document.pagesCount)) {
        throw ArgumentError('Invalid page number: $pageNumber');
      }

      // Get the page
      final page = await document.getPage(pageNumber);

      // Use quality-based DPI instead of zoom-based
      final dpi = getRecommendedDPI(options.quality, options.devicePixelRatio);

      final width = calculateRenderWidth(
        pageWidth: page.width,
        dpi: dpi,
      );

      final height = calculateRenderHeight(
        pageHeight: page.height,
        dpi: dpi,
      );

      // Debug: Log render dimensions
      debugPrint('📄 Rendering page $pageNumber: ${width.toInt()}x${height.toInt()} px (DPI: $dpi)');

      // Render the page
      final pageImage = await page.render(
        width: width,
        height: height,
        format: PdfPageImageFormat.png,
      );

      // Close the page
      await page.close();

      return pageImage?.bytes;
    } catch (e) {
      debugPrint('❌ PDF render error: $e');
      return null;
    }
  }

  /// Gets the size of a PDF page in points.
  Future<Size?> getPageSize(
    PdfDocument document,
    int pageNumber,
  ) async {
    try {
      if (!isValidPageNumber(pageNumber, document.pagesCount)) {
        return null;
      }

      final page = await document.getPage(pageNumber);
      final size = Size(page.width, page.height);
      await page.close();

      return size;
    } catch (e) {
      return null;
    }
  }
}
