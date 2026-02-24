import 'dart:async';
import 'package:drawing_core/drawing_core.dart';
import 'pdf_exporter.dart';
import 'raster_pdf_renderer.dart';

/// State of PDF export process.
enum PDFExportState {
  /// Idle, ready to start export.
  idle,

  /// Preparing pages for export.
  preparing,

  /// Exporting pages to PDF.
  exporting,

  /// Export completed successfully.
  completed,

  /// Export failed with error.
  error,
}

/// Configuration for PDF export.
class ExportConfiguration {
  /// Export mode.
  final PDFExportMode exportMode;

  /// Export quality.
  final PDFExportQuality quality;

  /// Whether to include backgrounds.
  final bool includeBackground;

  /// Page format.
  final PDFPageFormat? pageFormat;

  const ExportConfiguration({
    this.exportMode = PDFExportMode.vector,
    this.quality = PDFExportQuality.high,
    this.includeBackground = true,
    this.pageFormat,
  });

  /// Converts to PDFExportOptions.
  PDFExportOptions toExportOptions() {
    return PDFExportOptions(
      exportMode: exportMode,
      quality: quality,
      includeBackground: includeBackground,
      pageFormat: pageFormat,
    );
  }
}

/// Result of PDF export service operation.
class PDFExportServiceResult {
  /// Whether export was successful.
  final bool isSuccess;

  /// PDF file bytes.
  final List<int> pdfBytes;

  /// Error message if export failed.
  final String? errorMessage;

  const PDFExportServiceResult({
    required this.isSuccess,
    required this.pdfBytes,
    this.errorMessage,
  });

  /// Creates a successful result.
  factory PDFExportServiceResult.success(List<int> bytes) {
    return PDFExportServiceResult(
      isSuccess: true,
      pdfBytes: bytes,
    );
  }

  /// Creates an error result.
  factory PDFExportServiceResult.error(String message) {
    return PDFExportServiceResult(
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

/// Service for orchestrating PDF export workflow.
class PDFExportService {
  final PDFExporter _exporter;
  final RasterPDFRenderer _rasterRenderer;

  PDFExportState _state = PDFExportState.idle;
  String? _errorMessage;
  double _currentProgress = 0.0;
  int _totalPages = 0;
  int _processedPages = 0;
  bool _isDisposed = false;

  /// Stream controller for state changes.
  final _stateController = StreamController<PDFExportState>.broadcast();

  /// Stream controller for progress updates.
  final _progressController = StreamController<double>.broadcast();

  PDFExportService({
    PDFExporter? exporter,
    RasterPDFRenderer? rasterRenderer,
  })  : _exporter = exporter ?? PDFExporter(),
        _rasterRenderer = rasterRenderer ?? RasterPDFRenderer();

  /// Current export state.
  PDFExportState get state => _state;

  /// Stream of state changes.
  Stream<PDFExportState> get stateStream => _stateController.stream;

  /// Whether service is currently exporting.
  bool get isExporting =>
      _state == PDFExportState.preparing || _state == PDFExportState.exporting;

  /// Whether service has an error.
  bool get hasError => _state == PDFExportState.error;

  /// Current error message.
  String? get errorMessage => _errorMessage;

  /// Current progress (0.0 to 1.0).
  double get currentProgress => _currentProgress;

  /// Stream of progress updates.
  Stream<double> get progressStream => _progressController.stream;

  /// Total pages being processed.
  int get totalPages => _totalPages;

  /// Number of pages processed so far.
  int get processedPages => _processedPages;

  /// Progress percentage (0 to 100).
  int get progressPercentage => (_currentProgress * 100).round();

  /// Whether service is disposed.
  bool get isDisposed => _isDisposed;

  /// Validates a list of pages.
  bool validatePages(List<Page> pages) {
    if (pages.isEmpty) return false;

    for (final page in pages) {
      if (!isPageExportable(page)) {
        return false;
      }
    }

    return true;
  }

  /// Checks if a page is exportable.
  bool isPageExportable(Page page) {
    return page.size.width > 0 && page.size.height > 0;
  }

  /// Calculates progress.
  double calculateProgress({
    required int processedPages,
    required int totalPages,
  }) {
    if (totalPages == 0) return 0.0;
    return processedPages / totalPages;
  }

  /// Checks if can transition to a new state.
  bool canTransitionTo(PDFExportState newState) {
    // Can always transition to error
    if (newState == PDFExportState.error) return true;

    // Valid transitions
    switch (_state) {
      case PDFExportState.idle:
        return newState == PDFExportState.preparing;

      case PDFExportState.preparing:
        return newState == PDFExportState.exporting;

      case PDFExportState.exporting:
        return newState == PDFExportState.completed;

      case PDFExportState.completed:
      case PDFExportState.error:
        return newState == PDFExportState.idle ||
            newState == PDFExportState.preparing;
    }
  }

  /// Creates metadata from a document.
  PDFDocumentMetadata createMetadata(DrawingDocument document) {
    return PDFDocumentMetadata(
      title: document.title.isEmpty ? 'Untitled Document' : document.title,
      creator: 'StarNote',
    );
  }

  /// Recommends export mode for a page.
  PDFExportMode recommendExportMode(Page page) {
    if (_rasterRenderer.shouldUseRasterFallback(page)) {
      return PDFExportMode.raster;
    }
    return PDFExportMode.vector;
  }

  /// Exports pages to PDF.
  Future<PDFExportServiceResult> exportPages({
    required List<Page> pages,
    required ExportConfiguration config,
    PDFDocumentMetadata? metadata,
    void Function(double progress)? onProgress,
  }) async {
    _checkNotDisposed();

    if (!validatePages(pages)) {
      throw ArgumentError('Invalid pages for export');
    }

    try {
      // Update state
      _updateState(PDFExportState.preparing);
      _totalPages = pages.length;
      _processedPages = 0;
      _updateProgress(0.0);

      // Start export
      _updateState(PDFExportState.exporting);

      final result = await _exporter.exportPages(
        pages: pages,
        metadata: metadata,
        options: config.toExportOptions(),
        onProgress: (current, total) {
          final progress = total > 0 ? current / total : 0.0;
          _processedPages = current;
          _updateProgress(progress);
          onProgress?.call(progress);
        },
      );

      if (result.isSuccess) {
        _updateState(PDFExportState.completed);
        return PDFExportServiceResult.success(result.pdfBytes);
      } else {
        _setError(result.errorMessage ?? 'Unknown error');
        return PDFExportServiceResult.error(result.errorMessage ?? 'Unknown error');
      }
    } catch (e) {
      _setError(e.toString());
      return PDFExportServiceResult.error(e.toString());
    }
  }

  /// Exports a document to PDF.
  Future<PDFExportServiceResult> exportDocument({
    required DrawingDocument document,
    required ExportConfiguration config,
    void Function(double progress)? onProgress,
  }) async {
    final metadata = createMetadata(document);
    return exportPages(
      pages: document.pages,
      config: config,
      metadata: metadata,
      onProgress: onProgress,
    );
  }

  /// Generates a filename for the export.
  String generateFilename({
    required String documentTitle,
    String extension = 'pdf',
  }) {
    // Sanitize filename
    var filename = documentTitle.isEmpty ? 'document' : documentTitle;
    
    // Remove invalid characters
    filename = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    
    // Limit length
    if (filename.length > 200) {
      filename = filename.substring(0, 200);
    }

    return '$filename.$extension';
  }

  /// Generates a progress message.
  String generateProgressMessage({
    required int currentPage,
    required int totalPages,
  }) {
    if (totalPages == 1) {
      return 'Exporting page...';
    }
    return 'Exporting page $currentPage of $totalPages...';
  }

  /// Updates the current state.
  void _updateState(PDFExportState newState) {
    if (canTransitionTo(newState)) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  /// Updates progress.
  void _updateProgress(double progress) {
    _currentProgress = progress.clamp(0.0, 1.0);
    _progressController.add(_currentProgress);
  }

  /// Sets error state.
  void _setError(String message) {
    _errorMessage = message;
    _updateState(PDFExportState.error);
  }

  /// Checks if service is disposed.
  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError('PDFExportService has been disposed');
    }
  }

  /// Disposes the service.
  void dispose() {
    if (_isDisposed) return;

    _stateController.close();
    _progressController.close();
    _isDisposed = true;
  }
}
