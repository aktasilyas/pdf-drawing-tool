import 'dart:math' as math;
import 'package:drawing_core/drawing_core.dart';

/// Raster quality levels with associated DPI.
enum RasterQuality {
  /// Low quality (72 DPI).
  low,

  /// Medium quality (150 DPI).
  medium,

  /// High quality (300 DPI).
  high,

  /// Print quality (600 DPI).
  print;

  /// Gets DPI for this quality level.
  int get dpi {
    switch (this) {
      case RasterQuality.low:
        return 72;
      case RasterQuality.medium:
        return 150;
      case RasterQuality.high:
        return 300;
      case RasterQuality.print:
        return 600;
    }
  }
}

/// Raster image formats.
enum RasterImageFormat {
  /// PNG format (lossless, supports transparency).
  png,

  /// JPEG format (lossy, no transparency).
  jpeg;

  /// File extension for this format.
  String get extension {
    switch (this) {
      case RasterImageFormat.png:
        return 'png';
      case RasterImageFormat.jpeg:
        return 'jpg';
    }
  }

  /// Whether this format supports transparency.
  bool get supportsTransparency {
    switch (this) {
      case RasterImageFormat.png:
        return true;
      case RasterImageFormat.jpeg:
        return false;
    }
  }
}

/// Compression settings for raster export.
class CompressionSettings {
  /// Whether compression is enabled.
  final bool enabled;

  /// Compression quality (0-100).
  final int quality;

  CompressionSettings({
    this.enabled = true,
    this.quality = 90,
  }) {
    if (quality < 0 || quality > 100) {
      throw ArgumentError('Quality must be between 0 and 100');
    }
  }
}

/// Options for raster export.
class RasterExportOptions {
  /// Raster quality level.
  final RasterQuality quality;

  /// Image format.
  final RasterImageFormat format;

  /// Whether to enable antialiasing.
  final bool antialiasing;

  /// Compression settings.
  final CompressionSettings compression;

  /// Background color (ARGB).
  final int backgroundColor;

  RasterExportOptions({
    this.quality = RasterQuality.high,
    this.format = RasterImageFormat.png,
    this.antialiasing = true,
    CompressionSettings? compression,
    this.backgroundColor = 0xFFFFFFFF,
  }) : compression = compression ?? const CompressionSettings();

  /// Gets DPI from quality level.
  int get dpi => quality.dpi;
}

/// Raster size in pixels.
class RasterSize {
  final int width;
  final int height;

  const RasterSize({
    required this.width,
    required this.height,
  });

  /// Total pixel count.
  int get pixelCount => width * height;
}

/// Render target configuration.
class RenderTarget {
  final int width;
  final int height;
  final int dpi;

  const RenderTarget({
    required this.width,
    required this.height,
    required this.dpi,
  });

  /// Scale factor (DPI / 72).
  double get scaleFactor => dpi / 72.0;

  /// Total pixel area.
  int get pixelArea => width * height;
}

/// Page complexity metrics.
class ComplexityMetrics {
  /// Total number of strokes.
  final int strokeCount;

  /// Total number of shapes.
  final int shapeCount;

  /// Total number of text elements.
  final int textCount;

  /// Total number of drawing points.
  final int totalPoints;

  /// Complexity score (0-1, higher is more complex).
  final double complexityScore;

  const ComplexityMetrics({
    required this.strokeCount,
    required this.shapeCount,
    required this.textCount,
    required this.totalPoints,
    required this.complexityScore,
  });

  /// Total number of elements.
  int get totalElements => strokeCount + shapeCount + textCount;

  /// Whether page is considered complex.
  bool get isComplex => complexityScore > 0.5;
}

/// Service for raster-based PDF rendering.
///
/// This service handles complex content by rendering to raster images
/// instead of vector graphics, which can be more efficient for very
/// detailed or complex drawings.
class RasterPDFRenderer {
  /// Default DPI for raster rendering.
  final int defaultDPI;

  /// Complexity threshold for stroke count.
  static const int strokeCountThreshold = 1000;

  /// Complexity threshold for total points.
  static const int pointCountThreshold = 50000;

  RasterPDFRenderer({
    this.defaultDPI = 300,
  });

  /// Calculates raster size from page dimensions and DPI.
  RasterSize calculateRasterSize({
    required double pageWidth,
    required double pageHeight,
    required int dpi,
  }) {
    // Convert points to pixels using DPI
    // 1 point = 1/72 inch
    // pixels = points * (DPI / 72)
    final width = (pageWidth * dpi / 72).round();
    final height = (pageHeight * dpi / 72).round();

    return RasterSize(width: width, height: height);
  }

  /// Checks if a page is complex and might benefit from raster rendering.
  bool isPageComplex(Page page) {
    final metrics = calculateComplexityMetrics(page);
    return metrics.isComplex;
  }

  /// Determines if raster fallback should be used for a page.
  bool shouldUseRasterFallback(Page page) {
    return isPageComplex(page);
  }

  /// Calculates complexity metrics for a page.
  ComplexityMetrics calculateComplexityMetrics(Page page) {
    int strokeCount = 0;
    int shapeCount = 0;
    int textCount = 0;
    int totalPoints = 0;

    for (final layer in page.layers) {
      strokeCount += layer.strokes.length;
      shapeCount += layer.shapes.length;
      textCount += layer.texts.length;

      for (final stroke in layer.strokes) {
        totalPoints += stroke.points.length;
      }
    }

    // Calculate complexity score
    final strokeScore = (strokeCount / strokeCountThreshold).clamp(0.0, 1.0);
    final pointScore = (totalPoints / pointCountThreshold).clamp(0.0, 1.0);
    final complexityScore = (strokeScore + pointScore) / 2;

    return ComplexityMetrics(
      strokeCount: strokeCount,
      shapeCount: shapeCount,
      textCount: textCount,
      totalPoints: totalPoints,
      complexityScore: complexityScore,
    );
  }

  /// Estimates memory usage for raster rendering in bytes.
  int estimateMemoryUsage({
    required double width,
    required double height,
    required int dpi,
  }) {
    final size = calculateRasterSize(
      pageWidth: width,
      pageHeight: height,
      dpi: dpi,
    );

    // 4 bytes per pixel (RGBA)
    return size.pixelCount * 4;
  }

  /// Recommends optimal DPI based on page complexity.
  int recommendDPI(Page page) {
    final metrics = calculateComplexityMetrics(page);

    if (metrics.complexityScore < 0.3) {
      // Simple content - can use high DPI
      return 300;
    } else if (metrics.complexityScore < 0.6) {
      // Medium complexity - use medium DPI
      return 150;
    } else {
      // Complex content - use lower DPI to save memory
      return 72;
    }
  }

  /// Creates a render target for a page.
  RenderTarget createRenderTarget(
    Page page, {
    int? customDPI,
  }) {
    final dpi = customDPI ?? recommendDPI(page);
    final size = calculateRasterSize(
      pageWidth: page.size.width,
      pageHeight: page.size.height,
      dpi: dpi,
    );

    return RenderTarget(
      width: size.width,
      height: size.height,
      dpi: dpi,
    );
  }

  /// Calculates optimal compression quality based on content.
  int recommendCompressionQuality(Page page) {
    final metrics = calculateComplexityMetrics(page);

    if (metrics.complexityScore < 0.3) {
      // Simple content - can use high quality
      return 95;
    } else if (metrics.complexityScore < 0.6) {
      // Medium complexity - balance quality and size
      return 85;
    } else {
      // Complex content - prioritize file size
      return 75;
    }
  }

  /// Estimates output file size in bytes.
  int estimateFileSize({
    required int width,
    required int height,
    required RasterImageFormat format,
    required int quality,
  }) {
    final pixelCount = width * height;

    switch (format) {
      case RasterImageFormat.png:
        // PNG: ~2-4 bytes per pixel (compressed)
        return (pixelCount * 3).round();

      case RasterImageFormat.jpeg:
        // JPEG: varies by quality (0.5-2 bytes per pixel)
        final bytesPerPixel = 0.5 + (quality / 100) * 1.5;
        return (pixelCount * bytesPerPixel).round();
    }
  }

  /// Checks if raster rendering is feasible with available memory.
  bool canRenderWithMemory({
    required Page page,
    required int dpi,
    required int availableMemoryBytes,
  }) {
    final requiredMemory = estimateMemoryUsage(
      width: page.size.width,
      height: page.size.height,
      dpi: dpi,
    );

    // Use at most 80% of available memory
    return requiredMemory < (availableMemoryBytes * 0.8);
  }

  /// Calculates downscale factor to fit memory budget.
  double calculateDownscaleFactor({
    required Page page,
    required int targetDPI,
    required int availableMemoryBytes,
  }) {
    final targetMemory = estimateMemoryUsage(
      width: page.size.width,
      height: page.size.height,
      dpi: targetDPI,
    );

    if (targetMemory <= availableMemoryBytes) {
      return 1.0;
    }

    // Calculate scale factor to fit memory
    final scale = math.sqrt(availableMemoryBytes / targetMemory);
    return scale.clamp(0.25, 1.0); // Min 25% scale
  }

  /// Gets recommended format for page content.
  RasterImageFormat recommendFormat(Page page) {
    final metrics = calculateComplexityMetrics(page);

    // Use PNG for simple content (better quality)
    // Use JPEG for complex content (better compression)
    return metrics.complexityScore > 0.5
        ? RasterImageFormat.jpeg
        : RasterImageFormat.png;
  }
}
