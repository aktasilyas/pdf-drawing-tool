import 'dart:async';
import 'dart:io';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_loader.dart';
import 'pdf_page_renderer.dart';
import 'pdf_to_page_converter.dart';

/// State of the PDF import process.
enum PDFImportState {
  /// Idle, ready to start import.
  idle,

  /// Loading PDF document.
  loadingPDF,

  /// Rendering PDF pages.
  renderingPages,

  /// Converting PDF pages to Drawing pages.
  convertingPages,

  /// Import completed successfully.
  completed,

  /// Import failed with error.
  error,
}

/// Page selection mode for import.
enum PDFPageSelection {
  /// Import all pages.
  all,

  /// Import a page range.
  range,

  /// Import selected pages.
  selected,
}

/// Configuration for PDF import.
class PDFImportConfig {
  /// Page selection mode.
  final PDFPageSelection pageSelection;

  /// Start page for range selection (1-based).
  final int? startPage;

  /// End page for range selection (1-based).
  final int? endPage;

  /// Selected page numbers (1-based).
  final List<int>? selectedPages;

  /// Whether to embed PDF images.
  final bool embedImages;

  /// Render options for PDF pages.
  final PDFRenderOptions? renderOptions;

  const PDFImportConfig({
    this.pageSelection = PDFPageSelection.all,
    this.startPage,
    this.endPage,
    this.selectedPages,
    this.embedImages = true,
    this.renderOptions,
  });

  /// Creates config for importing all pages.
  factory PDFImportConfig.all({
    bool embedImages = true,
    PDFRenderOptions? renderOptions,
  }) {
    return PDFImportConfig(
      pageSelection: PDFPageSelection.all,
      embedImages: embedImages,
      renderOptions: renderOptions,
    );
  }

  /// Creates config for importing a page range.
  factory PDFImportConfig.pageRange({
    required int startPage,
    required int endPage,
    bool embedImages = true,
    PDFRenderOptions? renderOptions,
  }) {
    return PDFImportConfig(
      pageSelection: PDFPageSelection.range,
      startPage: startPage,
      endPage: endPage,
      embedImages: embedImages,
      renderOptions: renderOptions,
    );
  }

  /// Creates config for importing selected pages.
  factory PDFImportConfig.selectedPages({
    required List<int> pages,
    bool embedImages = true,
    PDFRenderOptions? renderOptions,
  }) {
    return PDFImportConfig(
      pageSelection: PDFPageSelection.selected,
      selectedPages: pages,
      embedImages: embedImages,
      renderOptions: renderOptions,
    );
  }

  /// Validates the configuration against total page count.
  bool isValid({required int totalPages}) {
    switch (pageSelection) {
      case PDFPageSelection.all:
        return true;

      case PDFPageSelection.range:
        if (startPage == null || endPage == null) return false;
        if (startPage! < 1 || endPage! > totalPages) return false;
        if (startPage! > endPage!) return false;
        return true;

      case PDFPageSelection.selected:
        if (selectedPages == null || selectedPages!.isEmpty) return false;
        for (final page in selectedPages!) {
          if (page < 1 || page > totalPages) return false;
        }
        return true;
    }
  }
}

/// Result of PDF import operation.
class PDFImportServiceResult {
  /// Whether the import was successful.
  final bool isSuccess;

  /// Imported pages.
  final List<Page> pages;

  /// Error message if import failed.
  final String? errorMessage;

  const PDFImportServiceResult({
    required this.isSuccess,
    required this.pages,
    this.errorMessage,
  });

  /// Creates a successful result.
  factory PDFImportServiceResult.success(List<Page> pages) {
    return PDFImportServiceResult(
      isSuccess: true,
      pages: pages,
    );
  }

  /// Creates an error result.
  factory PDFImportServiceResult.error(String message) {
    return PDFImportServiceResult(
      isSuccess: false,
      pages: const [],
      errorMessage: message,
    );
  }

  /// Creates a cancelled result.
  factory PDFImportServiceResult.cancelled() {
    return PDFImportServiceResult(
      isSuccess: false,
      pages: const [],
    );
  }
}

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
  List<int> generatePageRange({required int start, required int end}) {
    if (start > end) return [];
    return List.generate(end - start + 1, (index) => start + index);
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
  bool canTransitionTo(PDFImportState newState) {
    // Can always transition to error
    if (newState == PDFImportState.error) return true;

    // Valid transitions
    switch (_state) {
      case PDFImportState.idle:
        return newState == PDFImportState.loadingPDF;

      case PDFImportState.loadingPDF:
        return newState == PDFImportState.renderingPages ||
            newState == PDFImportState.convertingPages;

      case PDFImportState.renderingPages:
        return newState == PDFImportState.convertingPages;

      case PDFImportState.convertingPages:
        return newState == PDFImportState.completed;

      case PDFImportState.completed:
      case PDFImportState.error:
        return newState == PDFImportState.idle ||
            newState == PDFImportState.loadingPDF;
    }
  }

  /// Calculates optimal batch size for processing.
  int calculateOptimalBatchSize({
    required int totalPages,
    required int availableMemory,
  }) {
    const int maxBatchSize = 50;
    const int avgPageMemory = 10 * 1024 * 1024; // 10MB per page estimate

    final memoryBasedBatch = (availableMemory / avgPageMemory).floor();
    final batchSize = memoryBasedBatch.clamp(1, maxBatchSize);

    return batchSize > totalPages ? totalPages : batchSize;
  }

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

    try {
      _updateState(PDFImportState.loadingPDF);

      // 1. PDF'i app storage'a kopyala (orijinal dosya silinebilir)
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/pdfs');
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final pdfId = 'pdf_${DateTime.now().millisecondsSinceEpoch}';
      final pdfFile = File('${pdfDir.path}/$pdfId.pdf');
      await File(filePath).copy(pdfFile.path);

      // 2. Kopyalanan PDF'i aç (orijinal bytes RAM'de tutulmaz)
      final document = await _loader.loadFromFile(pdfFile.path);

      // Validate config
      if (!config.isValid(totalPages: document.pagesCount)) {
        await _loader.disposeDocument(document);
        throw ArgumentError('Invalid import configuration');
      }

      // Page count limit
      final pageNumbers = _getPageNumbers(config, document.pagesCount);
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

      // 3. Sayfa boyutlarını oku (render yok - sadece metadata)
      _updateState(PDFImportState.convertingPages);
      final pages = <Page>[];

      for (final pageNumber in pageNumbers) {
        PdfPage? pdfPage;
        try {
          pdfPage = await document.getPage(pageNumber);

          final page = Page(
            id: 'page_${DateTime.now().millisecondsSinceEpoch}_$pageNumber',
            index: pageNumber - 1,
            size: PageSize(width: pdfPage.width, height: pdfPage.height),
            background: PageBackground.pdfLazy(
              pageIndex: pageNumber,
              pdfFilePath: pdfFile.path,
            ),
            layers: [Layer.empty('Layer 1')],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          pages.add(page);
        } catch (e) {
          debugPrint('Warning: Could not load PDF page $pageNumber: $e');
          // Bozuk sayfayı atla, devam et
        } finally {
          try {
            await pdfPage?.close();
          } catch (_) {}
        }

        _processedPages++;
        _updateProgress(calculateProgress(
          processedPages: _processedPages,
          totalPages: _totalPages,
        ));
      }

      await _loader.disposeDocument(document);

      if (pages.isEmpty) {
        return PDFImportServiceResult.error(
          'PDF sayfaları okunamadı. Dosya bozuk olabilir.',
        );
      }

      _updateState(PDFImportState.completed);
      return PDFImportServiceResult.success(pages);
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

    try {
      // ═══════════════════════════════════════════════════════════════════
      // LAZY LOADING MODE: Save PDF to device, don't render pages
      // ═══════════════════════════════════════════════════════════════════
      if (useLazyLoading) {
        _updateState(PDFImportState.loadingPDF);

        // 1. PDF'i cihaza kaydet
        final appDir = await getApplicationDocumentsDirectory();
        final pdfDir = Directory('${appDir.path}/pdfs');
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }

        final pdfId = 'pdf_${DateTime.now().millisecondsSinceEpoch}';
        final pdfFile = File('${pdfDir.path}/$pdfId.pdf');
        await pdfFile.writeAsBytes(bytes);

        // 2. Dosyadan aç (bytes'ı tekrar RAM'e yüklemeden)
        final document = await _loader.loadFromFile(pdfFile.path);

        // Validate config
        if (!config.isValid(totalPages: document.pagesCount)) {
          await _loader.disposeDocument(document);
          throw ArgumentError('Invalid import configuration');
        }

        // Determine pages to import
        final pageNumbers = _getPageNumbers(config, document.pagesCount);

        // Page count limit
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

        _updateState(PDFImportState.convertingPages);

        final pages = <Page>[];

        for (final pageNumber in pageNumbers) {
          PdfPage? pdfPage;
          try {
            pdfPage = await document.getPage(pageNumber);

            // Sadece boyut bilgisi + dosya yolu kaydet, RENDER YOK
            final page = Page(
              id: 'page_${DateTime.now().millisecondsSinceEpoch}_$pageNumber',
              index: pageNumber - 1,
              size: PageSize(width: pdfPage.width, height: pdfPage.height),
              background: PageBackground.pdfLazy(
                pageIndex: pageNumber,
                pdfFilePath: pdfFile.path,
              ),
              layers: [Layer.empty('Layer 1')],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            pages.add(page);
          } catch (e) {
            debugPrint('Warning: Could not load PDF page $pageNumber: $e');
            // Bozuk sayfayı atla, devam et
          } finally {
            try {
              await pdfPage?.close();
            } catch (_) {}
          }

          _processedPages++;
          _updateProgress(calculateProgress(
            processedPages: _processedPages,
            totalPages: _totalPages,
          ));
        }

        await _loader.disposeDocument(document);

        if (pages.isEmpty) {
          return PDFImportServiceResult.error(
            'PDF sayfaları okunamadı. Dosya bozuk olabilir.',
          );
        }

        _updateState(PDFImportState.completed);
        return PDFImportServiceResult.success(pages);
      }
      
      // ═══════════════════════════════════════════════════════════════════
      // IMMEDIATE MODE: Legacy approach - render all pages now
      // ═══════════════════════════════════════════════════════════════════
      _updateState(PDFImportState.loadingPDF);
      final document = await _loader.loadFromBytes(bytes);

      // Validate config
      if (!config.isValid(totalPages: document.pagesCount)) {
        throw ArgumentError('Invalid import configuration');
      }

      // Determine pages to import
      final pageNumbers = _getPageNumbers(config, document.pagesCount);
      _totalPages = pageNumbers.length;
      _processedPages = 0;
      _updateProgress(0.0);

      // Convert pages (with immediate rendering)
      _updateState(PDFImportState.convertingPages);
      final pages = await _convertPages(
        document,
        pageNumbers,
        config,
        useLazyLoading: false,
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

  /// Gets page numbers to import based on config.
  List<int> _getPageNumbers(PDFImportConfig config, int totalPages) {
    switch (config.pageSelection) {
      case PDFPageSelection.all:
        return generatePageRange(start: 1, end: totalPages);

      case PDFPageSelection.range:
        return generatePageRange(
          start: config.startPage!,
          end: config.endPage!,
        );

      case PDFPageSelection.selected:
        return List.from(config.selectedPages!);
    }
  }

  /// Converts PDF pages to Drawing pages.
  Future<List<Page>> _convertPages(
    PdfDocument document,
    List<int> pageNumbers,
    PDFImportConfig config, {
    bool useLazyLoading = true,
  }) async {
    final pages = <Page>[];

    // IMMEDIATE MODE ONLY: Render pages now
    for (final pageNumber in pageNumbers) {
      final page = await _converter.convertPage(
        document,
        pageNumber,
        renderOptions: config.renderOptions ?? defaultRenderOptions,
        conversionOptions: PDFConversionOptions(
          embedImages: config.embedImages,
        ),
        useLazyLoading: false, // Force immediate rendering
      );

      if (page != null) {
        pages.add(page);
      }

      _processedPages++;
      _updateProgress(calculateProgress(
        processedPages: _processedPages,
        totalPages: _totalPages,
      ));
    }

    return pages;
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
