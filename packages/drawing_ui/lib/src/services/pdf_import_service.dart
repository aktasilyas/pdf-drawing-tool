import 'dart:async';
import 'dart:io';
import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:flutter/foundation.dart';
import 'pdf_import_errors.dart';
import 'pdf_import_models.dart';
import 'pdf_import_pages.dart';
import 'pdf_import_storage.dart';
import 'pdf_loader.dart';
import 'pdf_page_renderer.dart';
import 'pdf_to_page_converter.dart';

export 'pdf_import_errors.dart';
export 'pdf_import_models.dart';

/// Service for orchestrating PDF import workflow.
class PDFImportService {
  final PDFLoader _loader;
  // ignore: unused_field
  final PDFPageRenderer _renderer;
  final PDFToPageConverter _converter;
  final PDFRenderOptions defaultRenderOptions;
  final PdfPathResolver _pdfPaths;

  PDFImportState _state = PDFImportState.idle;
  String? _errorMessage;
  double _currentProgress = 0.0;
  int _totalPages = 0;
  int _processedPages = 0;
  bool _isDisposed = false;

  /// Stream controller for state changes.
  final _stateController = StreamController<PDFImportState>.broadcast();

  /// Stream controller for progress updates.
  final _progressController = StreamController<double>.broadcast();

  PDFImportService({
    PDFLoader? loader,
    PDFPageRenderer? renderer,
    PDFToPageConverter? converter,
    PDFRenderOptions? defaultRenderOptions,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  })  : _pdfPaths = pdfPaths,
        _loader = loader ?? PDFLoader(),
        _renderer = renderer ?? PDFPageRenderer(),
        _converter = converter ?? PDFToPageConverter(),
        defaultRenderOptions = defaultRenderOptions ?? const PDFRenderOptions();

  /// Current import state.
  PDFImportState get state => _state;

  /// Stream of state changes.
  Stream<PDFImportState> get stateStream => _stateController.stream;

  /// Whether service is currently loading.
  bool get isLoading =>
      _state == PDFImportState.loadingPDF ||
      _state == PDFImportState.renderingPages ||
      _state == PDFImportState.convertingPages;

  /// Whether service has an error.
  bool get hasError => _state == PDFImportState.error;

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

  /// Validates page selection.
  bool validatePageSelection({
    required List<int> pageNumbers,
    required int totalPages,
  }) {
    return isValidPdfPageSelection(pageNumbers, totalPages: totalPages);
  }

  /// Generates a page range.
  List<int> generatePageRange({required int start, required int end}) =>
      generatePdfPageRange(start: start, end: end);

  /// Calculates progress.
  double calculateProgress({
    required int processedPages,
    required int totalPages,
  }) {
    return totalPages == 0 ? 0.0 : processedPages / totalPages;
  }

  /// Checks if can transition to a new state.
  bool canTransitionTo(PDFImportState newState) =>
      _state.canTransitionTo(newState);

  /// Calculates optimal batch size for processing.
  int calculateOptimalBatchSize({
    required int totalPages,
    required int availableMemory,
  }) {
    return optimalPdfBatchSize(
      totalPages: totalPages,
      availableMemory: availableMemory,
    );
  }

  /// Maximum number of pages allowed for import.
  static const int maxPageCount = 500;

  /// Fails fast on a range that can never be valid, whatever the page count,
  /// before any file is written or loaded.
  void _checkRangeOrder(PDFImportConfig config) {
    if (config.pageSelection == PDFPageSelection.range &&
        config.startPage != null &&
        config.endPage != null &&
        config.startPage! > config.endPage!) {
      throw ArgumentError('Invalid import configuration');
    }
  }

  /// Imports PDF from file path with lazy loading.
  ///
  /// Copies the source PDF to app storage, then extracts page dimensions
  /// without rendering. Pages are rendered on-demand when displayed.
  Future<PDFImportServiceResult> importFromFile({
    required String filePath,
    required PDFImportConfig config,
  }) async {
    _checkNotDisposed();

    if (filePath.isEmpty) {
      throw ArgumentError('File path cannot be empty');
    }

    _checkRangeOrder(config);

    try {
      _updateState(PDFImportState.loadingPDF);

      // Copy the PDF to app storage (the original may be deleted), then
      // open the copy lazily. The copy is removed again on any failure.
      return await storePdfAndImport(
        file: await newImportedPdfFile(_pdfPaths),
        write: (file) => File(filePath).copy(file.path),
        import: (file) => _importLazily(file.path, config),
        isFailure: (result) => !result.isSuccess,
      );
    } catch (e) {
      final message = friendlyPdfImportError(e);
      _setError(message);
      return PDFImportServiceResult.error(message);
    }
  }

  /// Imports PDF from bytes.
  ///
  /// If [useLazyLoading] is true (default), pages are not rendered now: the
  /// PDF is saved to device storage and pages are rendered on demand, which
  /// is much faster for large PDFs.
  Future<PDFImportServiceResult> importFromBytes({
    required Uint8List bytes,
    required PDFImportConfig config,
    bool useLazyLoading = true,
  }) async {
    _checkNotDisposed();
    _checkRangeOrder(config);

    try {
      // LAZY LOADING MODE: save the PDF to device, don't render pages.
      if (useLazyLoading) {
        _updateState(PDFImportState.loadingPDF);
        return await storePdfAndImport(
          file: await newImportedPdfFile(_pdfPaths),
          write: (file) => file.writeAsBytes(bytes),
          import: (file) => _importLazily(file.path, config),
          isFailure: (result) => !result.isSuccess,
        );
      }

      // IMMEDIATE MODE: legacy approach - render all pages now.
      _updateState(PDFImportState.loadingPDF);
      final document = await _loader.loadFromBytes(bytes);

      // Validate config
      if (!config.isValid(totalPages: document.pagesCount)) {
        throw ArgumentError('Invalid import configuration');
      }

      // Determine pages to import
      final pageNumbers = pdfImportPageNumbers(config, document.pagesCount);
      _totalPages = pageNumbers.length;
      _processedPages = 0;
      _updateProgress(0.0);

      // Convert pages (with immediate rendering)
      _updateState(PDFImportState.convertingPages);
      final pages = await convertPdfPagesImmediately(
        document,
        pageNumbers,
        converter: _converter,
        renderOptions: config.renderOptions ?? defaultRenderOptions,
        embedImages: config.embedImages,
        onPageProcessed: _onPageProcessed,
      );

      // Cleanup
      await _loader.disposeDocument(document);

      _updateState(PDFImportState.completed);
      return PDFImportServiceResult.success(pages);
    } catch (e) {
      final message = friendlyPdfImportError(e);
      _setError(message);
      return PDFImportServiceResult.error(message);
    }
  }

  /// Opens the stored PDF at [absolutePath] and builds lazy pages (sizes and
  /// the container-relative file path only, rendered on demand). Throws
  /// [ArgumentError] when [config] does not fit the document.
  Future<PDFImportServiceResult> _importLazily(
    String absolutePath,
    PDFImportConfig config,
  ) async {
    final document = await _loader.loadFromFile(absolutePath);

    // Validate config
    if (!config.isValid(totalPages: document.pagesCount)) {
      await _loader.disposeDocument(document);
      throw ArgumentError('Invalid import configuration');
    }

    // Page count limit
    final pageNumbers = pdfImportPageNumbers(config, document.pagesCount);
    if (pageNumbers.length > maxPageCount) {
      await _loader.disposeDocument(document);
      return PDFImportServiceResult.error(
        'PDF çok fazla sayfa içeriyor (${pageNumbers.length}). '
        'Maksimum $maxPageCount sayfa destekleniyor.',
      );
    }

    _totalPages = pageNumbers.length;
    _processedPages = 0;
    _updateProgress(0.0);

    // Read page sizes only (no rendering).
    _updateState(PDFImportState.convertingPages);
    final pages = await buildLazyPdfPages(
      document,
      pageNumbers,
      pdfFilePath: _pdfPaths.toStored(absolutePath),
      onPageProcessed: _onPageProcessed,
    );

    await _loader.disposeDocument(document);

    if (pages.isEmpty) {
      return PDFImportServiceResult.error(
        'PDF sayfaları okunamadı. Dosya bozuk olabilir.',
      );
    }

    _updateState(PDFImportState.completed);
    return PDFImportServiceResult.success(pages);
  }

  /// Counts one processed page and publishes the new progress.
  void _onPageProcessed() {
    _processedPages++;
    _updateProgress(calculateProgress(
      processedPages: _processedPages,
      totalPages: _totalPages,
    ));
  }

  /// Updates the current state.
  void _updateState(PDFImportState newState) {
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
    _updateState(PDFImportState.error);
  }

  /// Checks if service is disposed.
  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError('PDFImportService has been disposed');
    }
  }

  /// Disposes the service.
  void dispose() {
    if (_isDisposed) return;

    _loader.dispose();
    _stateController.close();
    _progressController.close();
    _isDisposed = true;
  }
}
