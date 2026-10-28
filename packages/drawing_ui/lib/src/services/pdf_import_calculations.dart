import 'pdf_import_pages.dart';

/// Pure helpers of [PDFImportService]: no state, no I/O.
mixin PdfImportCalculations {
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
}
