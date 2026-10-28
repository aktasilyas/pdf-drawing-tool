import 'dart:async';
import 'dart:io';
import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:flutter/foundation.dart';
import 'pdf_import_errors.dart';
import 'pdf_import_calculations.dart';
import 'pdf_import_failure.dart';
import 'pdf_import_models.dart';
import 'pdf_import_pages.dart';
import 'pdf_import_storage.dart';
import 'pdf_loader.dart';
import 'pdf_page_renderer.dart';
import 'pdf_to_page_converter.dart';

export 'pdf_import_errors.dart';
export 'pdf_import_failure.dart';
export 'pdf_import_models.dart';

/// Service for orchestrating PDF import workflow.
class PDFImportService with PdfImportCalculations {
  final PDFLoader _loader;
  // ignore: unused_field
  final PDFPageRenderer _renderer;
  final PDFToPageConverter _converter;
  final PDFRenderOptions defaultRenderOptions;
  final PdfPathResolver _pdfPaths;

  PDFImportState _state = PDFImportState.idle;
  PdfImportFailure? _failure;
  double _currentProgress = 0.0;
  int _totalPages = 0;
  int _processedPages = 0;
  bool _isDisposed = false;

  final _stateController = StreamController<PDFImportState>.broadcast();

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

  /// Why the last import failed, if it did.
  PdfImportFailure? get failure => _failure;

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

  /// Checks if can transition to a new state.
  bool canTransitionTo(PDFImportState newState) =>
      _state.canTransitionTo(newState);

  /// Maximum number of pages allowed for import.
  static const int maxPageCount = 500;

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

    checkPdfImportRangeOrder(config);

    try {
      _updateState(PDFImportState.loadingPDF);

      // Copy the PDF to app storage (the original may be deleted), then
      // open the copy lazily. The copy is removed again on any failure.
      final result = await storePdfAndImport(
        file: await newImportedPdfFile(_pdfPaths),
        write: (file) => File(filePath).copy(file.path),
        import: (file) => _importLazily(file.path, config),
        isFailure: (result) => !result.isSuccess,
      );
      // Pages unreadable after open: a locked file on some platforms.
      if (result.failure?.error != PdfImportError.pagesUnreadable ||
          !await pdfFileLooksEncrypted(filePath)) {
        return result;
      }
      const locked = PdfImportFailure(PdfImportError.passwordProtected);
      _setError(locked);
      return PDFImportServiceResult.error(locked);
    } catch (e) {
      final failure = await pdfFileLooksEncrypted(filePath)
          ? const PdfImportFailure(PdfImportError.passwordProtected)
          : pdfImportFailureFor(e);
      _setError(failure);
      return PDFImportServiceResult.error(failure);
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
    checkPdfImportRangeOrder(config);

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
      final skipped = <int>[];
      final pages = await convertPdfPagesImmediately(
        document,
        pageNumbers,
        converter: _converter,
        renderOptions: config.renderOptions ?? defaultRenderOptions,
        embedImages: config.embedImages,
        onPageProcessed: _onPageProcessed,
        onPageSkipped: skipped.add,
      );
      await _loader.disposeDocument(document);

      _updateState(PDFImportState.completed);
      return PDFImportServiceResult.success(pages, skippedPages: skipped);
    } catch (e) {
      final failure = pdfImportFailureFor(e);
      _setError(failure);
      return PDFImportServiceResult.error(failure);
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
        PdfImportFailure(
          PdfImportError.tooManyPages,
          pageCount: pageNumbers.length,
          maxPages: maxPageCount,
        ),
      );
    }

    _totalPages = pageNumbers.length;
    _processedPages = 0;
    _updateProgress(0.0);

    // Read page sizes only (no rendering).
    _updateState(PDFImportState.convertingPages);
    final skipped = <int>[];
    final pages = await buildLazyPdfPages(
      document,
      pageNumbers,
      pdfFilePath: _pdfPaths.toStored(absolutePath),
      onPageProcessed: _onPageProcessed,
      onPageSkipped: skipped.add,
    );
    await _loader.disposeDocument(document);

    if (pages.isEmpty) {
      return PDFImportServiceResult.error(
        const PdfImportFailure(PdfImportError.pagesUnreadable),
      );
    }

    _updateState(PDFImportState.completed);
    return PDFImportServiceResult.success(pages, skippedPages: skipped);
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
  void _setError(PdfImportFailure failure) {
    _failure = failure;
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
