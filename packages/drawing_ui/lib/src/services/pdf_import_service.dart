import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'pdf_import_models.dart';
import 'pdf_import_pages.dart';
import 'pdf_loader.dart';
import 'pdf_page_renderer.dart';
import 'pdf_to_page_converter.dart';

export 'pdf_import_models.dart';

/// Service for orchestrating PDF import workflow.
class PDFImportService {
  final PDFLoader _loader;
  // ignore: unused_field
  final PDFPageRenderer _renderer;
  final PDFToPageConverter _converter;
  final PDFRenderOptions defaultRenderOptions;

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
  })  : _loader = loader ?? PDFLoader(),
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
    if (pageNumbers.isEmpty) return false;

    for (final pageNumber in pageNumbers) {
      if (pageNumber < 1 || pageNumber > totalPages) {
        return false;
      }
    }

    return true;
  }
  /// Generates a page range.
  List<int> generatePageRange({required int start, required int end}) =>
      generatePdfPageRange(start: start, end: end);

  /// Calculates progress.
  double calculateProgress({
    required int processedPages,
    required int totalPages,
  }) {
    if (totalPages == 0) return 0.0;
    return processedPages / totalPages;
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

      // 1. Copy the PDF to app storage (the original may be deleted).
      final pdfFile = await newImportedPdfFile();
      await File(filePath).copy(pdfFile.path);

      // 2. Open the copy lazily (original bytes are not kept in RAM).
      return await _importLazily(pdfFile.path, config);
    } catch (e) {
      _setError(e.toString());
      return PDFImportServiceResult.error(e.toString());
    }
  }

  /// Imports PDF from bytes.
  ///
  /// If [useLazyLoading] is true (default), pages will not be rendered immediately.
  /// Instead, the PDF is saved to device storage and pages are rendered on-demand.
  /// This significantly improves import performance for large PDFs.
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
        final pdfFile = await newImportedPdfFile();
        await pdfFile.writeAsBytes(bytes);
        return await _importLazily(pdfFile.path, config);
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
      _setError(e.toString());
      return PDFImportServiceResult.error(e.toString());
    }
  }

  /// Opens the stored PDF at [pdfFilePath] and builds lazy pages (sizes and
  /// file path only, rendered on demand). Throws [ArgumentError] when
  /// [config] does not fit the document.
  Future<PDFImportServiceResult> _importLazily(
    String pdfFilePath,
    PDFImportConfig config,
  ) async {
    final document = await _loader.loadFromFile(pdfFilePath);

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
      pdfFilePath: pdfFilePath,
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
