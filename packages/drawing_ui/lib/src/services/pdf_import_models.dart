import 'package:drawing_core/drawing_core.dart';

import 'pdf_import_failure.dart';
import 'pdf_page_renderer.dart';

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

  /// Why the import failed, if it did.
  final PdfImportFailure? failure;

  /// 1-based numbers of the PDF pages that could not be read and are missing
  /// from [pages]. Empty when every page was imported.
  final List<int> skippedPages;

  const PDFImportServiceResult({
    required this.isSuccess,
    required this.pages,
    this.failure,
    this.skippedPages = const [],
  });

  /// Creates a successful result; [skippedPages] lists unreadable pages.
  factory PDFImportServiceResult.success(
    List<Page> pages, {
    List<int> skippedPages = const [],
  }) {
    return PDFImportServiceResult(
      isSuccess: true,
      pages: pages,
      skippedPages: List.unmodifiable(skippedPages),
    );
  }

  /// Whether some pages could not be read and were left out.
  bool get hasSkippedPages => skippedPages.isNotEmpty;

  /// Creates an error result.
  factory PDFImportServiceResult.error(PdfImportFailure failure) {
    return PDFImportServiceResult(
      isSuccess: false,
      pages: const [],
      failure: failure,
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

/// Allowed transitions of the import state machine.
extension PDFImportStateTransitions on PDFImportState {
  /// Whether the import may move from this state to [newState].
  bool canTransitionTo(PDFImportState newState) {
    // Can always transition to error
    if (newState == PDFImportState.error) return true;

    // Valid transitions
    switch (this) {
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
}
