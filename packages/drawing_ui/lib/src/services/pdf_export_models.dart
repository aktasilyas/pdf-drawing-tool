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

  const PDFExportOptions({
    this.includeBackground = true,
    this.exportMode = PDFExportMode.hybrid,
    this.quality = PDFExportQuality.medium,
    this.pageFormat,
    this.isInfiniteCanvas = false,
  });

  PDFExportOptions copyWith({
    bool? includeBackground,
    PDFExportMode? exportMode,
    PDFExportQuality? quality,
    PDFPageFormat? pageFormat,
    bool? isInfiniteCanvas,
  }) {
    return PDFExportOptions(
      includeBackground: includeBackground ?? this.includeBackground,
      exportMode: exportMode ?? this.exportMode,
      quality: quality ?? this.quality,
      pageFormat: pageFormat ?? this.pageFormat,
      isInfiniteCanvas: isInfiniteCanvas ?? this.isInfiniteCanvas,
    );
  }
}

/// Result of PDF export operation.
class PDFExportResult {
  final bool isSuccess;
  final List<int> pdfBytes;
  final String? errorMessage;

  const PDFExportResult({
    required this.isSuccess,
    required this.pdfBytes,
    this.errorMessage,
  });

  factory PDFExportResult.success(List<int> bytes) =>
      PDFExportResult(isSuccess: true, pdfBytes: bytes);

  factory PDFExportResult.error(String message) => PDFExportResult(
        isSuccess: false,
        pdfBytes: const [],
        errorMessage: message,
      );

  factory PDFExportResult.cancelled() => PDFExportResult(
        isSuccess: false,
        pdfBytes: const [],
        errorMessage: null,
      );

  bool get wasCancelled => !isSuccess && errorMessage == null;

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
    this.creator = 'StarNote',
  });
}
