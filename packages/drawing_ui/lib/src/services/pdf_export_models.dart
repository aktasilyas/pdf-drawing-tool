import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:pdf/pdf.dart';

/// PDF export mode.
enum PDFExportMode { vector, raster, hybrid }

/// PDF export quality level.
enum PDFExportQuality {
  low,
  medium,
  high,
  print;

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

/// PDF page format.
class PDFPageFormat {
  final double width;
  final double height;

  const PDFPageFormat({required this.width, required this.height});

  static const a4 = PDFPageFormat(width: 595, height: 842);
  static const a5 = PDFPageFormat(width: 420, height: 595);
  static const letter = PDFPageFormat(width: 612, height: 792);
  static const legal = PDFPageFormat(width: 612, height: 1008);

  PdfPageFormat toPdfPageFormat() => PdfPageFormat(width, height);
}

/// Options for PDF export.
class PDFExportOptions {
  final bool includeBackground;
  final PDFExportMode exportMode;
  final PDFExportQuality quality;
  final PDFPageFormat? pageFormat;
  final bool isInfiniteCanvas;

  /// When true, adds a small "ElyaNotes" watermark to the bottom-right corner
  /// of each page. Used for free-tier exports.
  final bool addWatermark;

  const PDFExportOptions({
    this.includeBackground = true,
    this.exportMode = PDFExportMode.hybrid,
    this.quality = PDFExportQuality.medium,
    this.pageFormat,
    this.isInfiniteCanvas = false,
    this.addWatermark = false,
  });

  PDFExportOptions copyWith({
    bool? includeBackground,
    PDFExportMode? exportMode,
    PDFExportQuality? quality,
    PDFPageFormat? pageFormat,
    bool? isInfiniteCanvas,
    bool? addWatermark,
  }) {
    return PDFExportOptions(
      includeBackground: includeBackground ?? this.includeBackground,
      exportMode: exportMode ?? this.exportMode,
      quality: quality ?? this.quality,
      pageFormat: pageFormat ?? this.pageFormat,
      isInfiniteCanvas: isInfiniteCanvas ?? this.isInfiniteCanvas,
      addWatermark: addWatermark ?? this.addWatermark,
    );
  }
}

/// Result of PDF export operation.
class PDFExportResult {
  final bool isSuccess;
  final List<int> pdfBytes;
  final ExportFailure? failure;

  /// 1-based positions, in the exported page list, of pages written without
  /// their PDF background because it could not be loaded.
  final List<int> missingBackgroundPages;

  const PDFExportResult({
    required this.isSuccess,
    required this.pdfBytes,
    this.failure,
    this.missingBackgroundPages = const [],
  });

  factory PDFExportResult.success(
    List<int> bytes, {
    List<int> missingBackgroundPages = const [],
  }) =>
      PDFExportResult(
        isSuccess: true,
        pdfBytes: bytes,
        missingBackgroundPages: List.unmodifiable(missingBackgroundPages),
      );

  factory PDFExportResult.error(ExportFailure failure) => PDFExportResult(
        isSuccess: false,
        pdfBytes: const [],
        failure: failure,
      );

  factory PDFExportResult.cancelled() => PDFExportResult(
        isSuccess: false,
        pdfBytes: const [],
      );

  bool get wasCancelled => !isSuccess && failure == null;

  int get fileSizeBytes => pdfBytes.length;

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// PDF document metadata.
class PDFDocumentMetadata {
  final String? title;
  final String? author;
  final String? creator;

  const PDFDocumentMetadata({
    this.title,
    this.author,
    this.creator = 'Elyanotes',
  });
}
