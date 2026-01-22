import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drawing_core/drawing_core.dart';

/// PDF page format.
class PDFPageFormat {
  final double width;
  final double height;

  const PDFPageFormat({
    required this.width,
    required this.height,
  });

  /// A4 format (595 x 842 points).
  static const a4 = PDFPageFormat(width: 595, height: 842);

  /// A5 format (420 x 595 points).
  static const a5 = PDFPageFormat(width: 420, height: 595);

  /// Letter format (612 x 792 points).
  static const letter = PDFPageFormat(width: 612, height: 792);

  /// Legal format (612 x 1008 points).
  static const legal = PDFPageFormat(width: 612, height: 1008);

  /// Creates a custom page format.
  factory PDFPageFormat.custom({
    required double width,
    required double height,
  }) {
    return PDFPageFormat(width: width, height: height);
  }

  /// Converts to pdf package PdfPageFormat.
  PdfPageFormat toPdfPageFormat() {
    return PdfPageFormat(width, height);
  }
}

/// PDF export mode.
enum PDFExportMode {
  /// Export as vector graphics (strokes, shapes).
  vector,

  /// Export as raster images.
  raster,

  /// Hybrid mode (vector where possible, raster fallback).
  hybrid,
}

/// PDF export quality level.
enum PDFExportQuality {
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
      case PDFExportQuality.low:
        return 72;
      case PDFExportQuality.medium:
        return 150;
      case PDFExportQuality.high:
        return 300;
      case PDFExportQuality.print:
        return 600;
    }
  }
}

/// Options for PDF export.
class PDFExportOptions {
  /// Whether to include page backgrounds.
  final bool includeBackground;

  /// Export mode (vector/raster/hybrid).
  final PDFExportMode exportMode;

  /// Export quality level.
  final PDFExportQuality quality;

  /// Page format for the PDF.
  final PDFPageFormat? pageFormat;

  const PDFExportOptions({
    this.includeBackground = true,
    this.exportMode = PDFExportMode.vector,
    this.quality = PDFExportQuality.high,
    this.pageFormat,
  });

  /// Creates a copy with new values.
  PDFExportOptions copyWith({
    bool? includeBackground,
    PDFExportMode? exportMode,
    PDFExportQuality? quality,
    PDFPageFormat? pageFormat,
  }) {
    return PDFExportOptions(
      includeBackground: includeBackground ?? this.includeBackground,
      exportMode: exportMode ?? this.exportMode,
      quality: quality ?? this.quality,
      pageFormat: pageFormat ?? this.pageFormat,
    );
  }
}

/// PDF output format.
enum PDFOutputFormat {
  pdf;

  /// File extension for this format.
  String get extension => 'pdf';

  /// MIME type for this format.
  String get mimeType => 'application/pdf';
}

/// Result of PDF export operation.
class PDFExportResult {
  /// Whether export was successful.
  final bool isSuccess;

  /// PDF file bytes.
  final List<int> pdfBytes;

  /// Error message if export failed.
  final String? errorMessage;

  const PDFExportResult({
    required this.isSuccess,
    required this.pdfBytes,
    this.errorMessage,
  });

  /// Creates a successful result.
  factory PDFExportResult.success(List<int> bytes) {
    return PDFExportResult(
      isSuccess: true,
      pdfBytes: bytes,
    );
  }

  /// Creates an error result.
  factory PDFExportResult.error(String message) {
    return PDFExportResult(
      isSuccess: false,
      pdfBytes: const [],
      errorMessage: message,
    );
  }

  /// File size in bytes.
  int get fileSizeBytes => pdfBytes.length;

  /// Formatted file size.
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// PDF document metadata.
class PDFDocumentMetadata {
  final String? title;
  final String? author;
  final String? subject;
  final List<String>? keywords;
  final String? creator;

  const PDFDocumentMetadata({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator = 'StarNote',
  });
}

/// PDF size representation.
class PDFSize {
  final double width;
  final double height;

  const PDFSize(this.width, this.height);
}

/// Service for exporting Drawing pages to PDF.
class PDFExporter {
  /// Default page format.
  final PDFPageFormat defaultPageFormat;

  PDFExporter({
    this.defaultPageFormat = PDFPageFormat.a4,
  });

  /// Checks if a page is exportable.
  bool isPageExportable(Page page) {
    // Check if page has valid dimensions
    if (page.size.width <= 0 || page.size.height <= 0) {
      return false;
    }

    // Empty pages are still exportable (for background)
    return true;
  }

  /// Calculates PDF size from page size.
  PDFSize calculatePDFSize(PageSize pageSize) {
    return PDFSize(pageSize.width, pageSize.height);
  }

  /// Converts drawing coordinates to PDF coordinates.
  ///
  /// Drawing has origin at top-left, PDF at bottom-left.
  (double, double) convertCoordinates({
    required double drawingX,
    required double drawingY,
    required double pageHeight,
  }) {
    return (drawingX, pageHeight - drawingY);
  }

  /// Calculates export progress.
  double calculateProgress({
    required int currentPage,
    required int totalPages,
  }) {
    if (totalPages == 0) return 0.0;
    return currentPage / totalPages;
  }

  /// Exports multiple pages to a PDF document.
  Future<PDFExportResult> exportPages({
    required List<Page> pages,
    required PDFExportOptions options,
    PDFDocumentMetadata? metadata,
    void Function(double progress)? onProgress,
  }) async {
    if (pages.isEmpty) {
      throw ArgumentError('Pages list cannot be empty');
    }

    try {
      final pdf = pw.Document();

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];

        if (!isPageExportable(page)) {
          continue;
        }

        // Create PDF page
        final pdfPage = await _createPDFPage(page, options);
        pdf.addPage(pdfPage);

        // Report progress
        onProgress?.call(calculateProgress(
          currentPage: i + 1,
          totalPages: pages.length,
        ));
      }

      // Set metadata
      if (metadata != null) {
        pdf.info = pw.DocumentInfo(
          pdf.document,
          title: metadata.title,
          author: metadata.author,
          subject: metadata.subject,
          keywords: metadata.keywords?.join(', '),
          creator: metadata.creator,
        );
      }

      // Generate PDF bytes
      final bytes = await pdf.save();

      return PDFExportResult.success(bytes);
    } catch (e) {
      return PDFExportResult.error(e.toString());
    }
  }

  /// Exports a single page to PDF.
  Future<PDFExportResult> exportPage({
    required Page page,
    required PDFExportOptions options,
    PDFDocumentMetadata? metadata,
  }) async {
    return exportPages(
      pages: [page],
      options: options,
      metadata: metadata,
    );
  }

  /// Creates a PDF page from a Drawing page.
  Future<pw.Page> _createPDFPage(
    Page page,
    PDFExportOptions options,
  ) async {
    final pageSize = calculatePDFSize(page.size);
    final pageFormat = options.pageFormat?.toPdfPageFormat() ??
        PdfPageFormat(pageSize.width, pageSize.height);

    return pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.CustomPaint(
          painter: (canvas, size) {
            // Draw background
            if (options.includeBackground) {
              _drawBackground(canvas, size, page.background);
            }

            // Draw content based on export mode
            switch (options.exportMode) {
              case PDFExportMode.vector:
                _drawVectorContent(canvas, page, pageSize.height);
                break;
              case PDFExportMode.raster:
                // Raster mode would render to image first
                // Not implemented in this basic version
                _drawVectorContent(canvas, page, pageSize.height);
                break;
              case PDFExportMode.hybrid:
                _drawVectorContent(canvas, page, pageSize.height);
                break;
            }
          },
        );
      },
    );
  }

  /// Draws page background.
  void _drawBackground(
    PdfGraphics canvas,
    PdfPoint size,
    PageBackground background,
  ) {
    if (background.type == BackgroundType.solid) {
      final color = _convertColor(background.color);
      canvas
        ..setFillColor(color)
        ..drawRect(0, 0, size.x, size.y)
        ..fillPath();
    }
    // Other background types (grid, lines) can be added here
  }

  /// Draws vector content (strokes, shapes, text).
  void _drawVectorContent(
    PdfGraphics canvas,
    Page page,
    double pageHeight,
  ) {
    // Draw all layers
    for (final layer in page.layers) {
      if (!layer.isVisible) continue;

      // Draw strokes
      for (final stroke in layer.strokes) {
        _drawStroke(canvas, stroke, pageHeight);
      }

      // Draw shapes
      for (final shape in layer.shapes) {
        _drawShape(canvas, shape, pageHeight);
      }

      // Draw texts
      for (final text in layer.texts) {
        _drawText(canvas, text, pageHeight);
      }
    }
  }

  /// Draws a stroke.
  void _drawStroke(PdfGraphics canvas, Stroke stroke, double pageHeight) {
    if (stroke.points.length < 2) return;

    final color = _convertColor(stroke.style.color);
    canvas
      ..setStrokeColor(color)
      ..setLineWidth(stroke.style.thickness);

    final firstPoint = stroke.points.first;
    final (x, y) = convertCoordinates(
      drawingX: firstPoint.x,
      drawingY: firstPoint.y,
      pageHeight: pageHeight,
    );

    canvas.moveTo(x, y);

    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      final (px, py) = convertCoordinates(
        drawingX: point.x,
        drawingY: point.y,
        pageHeight: pageHeight,
      );
      canvas.lineTo(px, py);
    }

    canvas.strokePath();
  }

  /// Draws a shape.
  void _drawShape(PdfGraphics canvas, Shape shape, double pageHeight) {
    final color = _convertColor(shape.strokeColor);
    canvas
      ..setStrokeColor(color)
      ..setLineWidth(shape.strokeWidth);

    final (x, y) = convertCoordinates(
      drawingX: shape.bounds.left,
      drawingY: shape.bounds.top,
      pageHeight: pageHeight,
    );

    final width = shape.bounds.width;
    final height = shape.bounds.height;

    switch (shape.type) {
      case ShapeType.rectangle:
        canvas.drawRect(x, y - height, width, height);
        break;
      case ShapeType.ellipse:
        canvas.drawEllipse(
          x + width / 2,
          y - height / 2,
          width / 2,
          height / 2,
        );
        break;
      case ShapeType.line:
        canvas
          ..moveTo(x, y)
          ..lineTo(x + width, y - height);
        break;
      case ShapeType.triangle:
      case ShapeType.diamond:
        // Basic implementations
        canvas.drawRect(x, y - height, width, height);
        break;
    }

    if (shape.isFilled) {
      canvas.fillPath();
    } else {
      canvas.strokePath();
    }
  }

  /// Draws text.
  void _drawText(PdfGraphics canvas, DrawingText text, double pageHeight) {
    // Basic text rendering
    // Full text support would require font handling
    final (x, y) = convertCoordinates(
      drawingX: text.bounds.left,
      drawingY: text.bounds.top,
      pageHeight: pageHeight,
    );

    // Text rendering in PDF requires fonts
    // This is a placeholder for the structure
    // Actual implementation would use pw.Text widget instead of CustomPaint
  }

  /// Converts ARGB color to PDF color.
  PdfColor _convertColor(int argbColor) {
    final a = (argbColor >> 24) & 0xFF;
    final r = (argbColor >> 16) & 0xFF;
    final g = (argbColor >> 8) & 0xFF;
    final b = argbColor & 0xFF;

    return PdfColor(r / 255, g / 255, b / 255);
  }
}
